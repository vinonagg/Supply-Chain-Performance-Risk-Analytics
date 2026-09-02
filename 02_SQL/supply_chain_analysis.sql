/* =====================================================================================
   SUPPLY CHAIN PERFORMANCE & RISK ANALYTICS SYSTEM
   MySQL 8.0  |  Phase 4 - Schema, Import, Master Fact View, 15 Analytical Queries
   -------------------------------------------------------------------------------------
   Author        : BI Analytics Team
   Source        : Five Excel-cleaned CSVs exported from 01_Cleaned_Data/
   Design notes  : - NO data-cleaning logic in this script (done in Excel / Phase 2).
                   - Analytical queries only, each with the business question it answers.
                   - Industry benchmark used for delivery: 85% On-Time (APICS / Gartner).
   Row counts (cleaned) : vendor_master 1,000 | purchase_orders 49,914 |
                          inventory_summary 30,000 | shipments 19,950 | returns 4,970
   ===================================================================================== */

-- ------------------------------------------------------------------------------------
-- 0. SCHEMA
-- ------------------------------------------------------------------------------------
DROP DATABASE IF EXISTS supply_chain_db;
CREATE DATABASE supply_chain_db CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
USE supply_chain_db;

-- ------------------------------------------------------------------------------------
-- 1. TABLE DDL  (structure matches the cleaned CSV headers 1:1)
-- ------------------------------------------------------------------------------------
DROP TABLE IF EXISTS vendor_master_clean;
CREATE TABLE vendor_master_clean (
    Vendor_ID               VARCHAR(12)  NOT NULL,
    Vendor_Name             VARCHAR(80),
    Vendor_Category         VARCHAR(40),
    Country                 VARCHAR(40),
    Reliability_Score       DECIMAL(5,1),          -- NULL when original value was out of 0-100
    Reliability_Score_Flag  VARCHAR(24),           -- 'Valid' | 'Out of Range (0-100)'
    Lead_Time_Days          INT,                   -- category-median imputed, negatives removed
    Vendor_Tier             VARCHAR(14),           -- Tier 1 >=80 | Tier 2 60-79 | Tier 3 <60 | Unclassified
    Contact_Email           VARCHAR(120),
    Active_Since_Year       INT,
    PRIMARY KEY (Vendor_ID)
);

DROP TABLE IF EXISTS purchase_orders_clean;
CREATE TABLE purchase_orders_clean (
    PO_ID                   VARCHAR(14)  NOT NULL,
    Vendor_ID               VARCHAR(12),
    Product_Category        VARCHAR(40),
    Product_SKU             VARCHAR(14),
    Order_Date              DATE,                  -- 51 rows legitimately NULL (unrecoverable)
    Expected_Delivery_Date  DATE,
    Actual_Delivery_Date    DATE,                  -- NULL = not yet delivered / invalid date removed
    Ordered_Quantity        INT,
    Unit_Price_INR          DECIMAL(12,2),
    Total_Order_Value       DECIMAL(18,2),         -- = Ordered_Quantity * Unit_Price_INR
    Order_Status            VARCHAR(24),           -- Pending|Partially Received|Received|Cancelled|In Transit|Unknown
    Warehouse_ID            VARCHAR(6),
    Delivery_Delay_Days     INT,                   -- = Actual_Delivery_Date - Expected_Delivery_Date
    Late_Delivery           TINYINT,               -- 1 when Delivery_Delay_Days > 0
    Order_Month             VARCHAR(7),            -- 'YYYY-MM'
    Order_Quarter           VARCHAR(6),            -- 'YYYYQn'
    PRIMARY KEY (PO_ID),
    KEY ix_po_vendor (Vendor_ID),
    KEY ix_po_sku (Product_SKU)
);

DROP TABLE IF EXISTS inventory_summary_clean;
CREATE TABLE inventory_summary_clean (
    Inventory_ID              VARCHAR(12) NOT NULL,
    Product_SKU               VARCHAR(14),
    Product_Name              VARCHAR(60),
    Product_Category          VARCHAR(40),
    Warehouse_ID              VARCHAR(6),
    Warehouse_Location        VARCHAR(40),
    Stock_On_Hand             INT,
    Reorder_Level             INT,
    Units_Sold_Last_Month     INT,
    Avg_Stock_On_Hand         INT,
    Snapshot_Date             DATE,
    Supplier_Lead_Time_Days   INT,
    Inventory_Turnover_Rate   DECIMAL(10,2),       -- = (Units_Sold_Last_Month * 12) / Avg_Stock_On_Hand
    Months_Of_Supply          DECIMAL(10,2),
    Stockout_Risk             TINYINT,             -- 1 when Stock_On_Hand < Reorder_Level
    Overstock_Risk            TINYINT,             -- 1 when Stock_On_Hand > 2 * Avg_Stock_On_Hand
    SKU_In_Purchase_Orders    TINYINT,             -- SKU consistency flag vs purchase_orders_clean
    PRIMARY KEY (Inventory_ID),
    KEY ix_inv_sku (Product_SKU),
    KEY ix_inv_wh (Warehouse_ID)
);

DROP TABLE IF EXISTS shipments_clean;
CREATE TABLE shipments_clean (
    Shipment_ID             VARCHAR(14) NOT NULL,
    PO_ID                   VARCHAR(14),
    Vendor_ID               VARCHAR(12),
    Shipment_Mode           VARCHAR(16),           -- Road | Rail | Air | Sea | Unknown
    Carrier_Name            VARCHAR(40),
    Dispatch_Date           DATE,
    Delivered_Date          DATE,                  -- NULL = in transit / invalid date removed
    Freight_Cost_INR        DECIMAL(14,2),
    Shipment_Weight_KG      DECIMAL(12,1),
    Freight_Cost_Per_KG     DECIMAL(12,2),
    Origin_Country          VARCHAR(40),
    Destination_Warehouse   VARCHAR(6),
    Damage_Flag             VARCHAR(4),            -- Yes | No
    Transit_Days            INT,                   -- = Delivered_Date - Dispatch_Date
    Month_Start             DATE,                  -- first day of Dispatch_Date month
    PRIMARY KEY (Shipment_ID),
    KEY ix_ship_po (PO_ID),
    KEY ix_ship_vendor (Vendor_ID)
);

DROP TABLE IF EXISTS returns_clean;
CREATE TABLE returns_clean (
    Return_ID           VARCHAR(14) NOT NULL,
    PO_ID               VARCHAR(14),
    Vendor_ID           VARCHAR(12),
    Product_SKU         VARCHAR(14),
    Product_Category    VARCHAR(40),
    Return_Date         DATE,
    Return_Reason       VARCHAR(40),               -- 7 canonical reasons | Unknown
    Return_Qty          INT,                       -- > 0 only
    Unit_Price_INR      DECIMAL(12,2),
    Return_Value        DECIMAL(18,2),             -- = Return_Qty * Unit_Price_INR
    High_Value_Return   TINYINT,                   -- 1 when Return_Value >= 90th percentile
    Approved_By         VARCHAR(24),
    Refund_Status       VARCHAR(16),               -- Processed | Pending | Rejected | Unknown
    Return_Month        VARCHAR(7),
    PRIMARY KEY (Return_ID),
    KEY ix_ret_vendor (Vendor_ID),
    KEY ix_ret_po (PO_ID)
);

-- ------------------------------------------------------------------------------------
-- 2. DATA IMPORT
--    Preferred : MySQL Workbench > Server > Data Import > "Table Data Import Wizard"
--                (one run per CSV, mapping every column, header row = yes).
--    Scripted alternative (requires local_infile=1 on client & server):
-- ------------------------------------------------------------------------------------
-- SET GLOBAL local_infile = 1;
/*
LOAD DATA LOCAL INFILE '01_Cleaned_Data/vendor_master_clean.csv'
INTO TABLE vendor_master_clean
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '\n'
IGNORE 1 LINES;

LOAD DATA LOCAL INFILE '01_Cleaned_Data/purchase_orders_clean.csv'
INTO TABLE purchase_orders_clean
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '\n'
IGNORE 1 LINES
(PO_ID,Vendor_ID,Product_Category,Product_SKU,@Order_Date,@Expected_Delivery_Date,
 @Actual_Delivery_Date,Ordered_Quantity,Unit_Price_INR,Total_Order_Value,Order_Status,
 Warehouse_ID,@Delivery_Delay_Days,@Late_Delivery,Order_Month,Order_Quarter)
SET Order_Date            = NULLIF(@Order_Date,''),
    Expected_Delivery_Date= NULLIF(@Expected_Delivery_Date,''),
    Actual_Delivery_Date  = NULLIF(@Actual_Delivery_Date,''),
    Delivery_Delay_Days   = NULLIF(@Delivery_Delay_Days,''),
    Late_Delivery         = NULLIF(@Late_Delivery,'');
-- (repeat pattern for inventory_summary_clean, shipments_clean, returns_clean)
*/

-- 2a. Import validation — compare against cleaned Excel row counts
SELECT 'vendor_master_clean'     AS table_name, COUNT(*) AS row_count, 1000  AS expected FROM vendor_master_clean
UNION ALL SELECT 'purchase_orders_clean',   COUNT(*), 49914 FROM purchase_orders_clean
UNION ALL SELECT 'inventory_summary_clean', COUNT(*), 30000 FROM inventory_summary_clean
UNION ALL SELECT 'shipments_clean',         COUNT(*), 19950 FROM shipments_clean
UNION ALL SELECT 'returns_clean',           COUNT(*), 4970  FROM returns_clean;

-- 2b. Product_SKU consistency check (Purchase Orders vs Inventory) BEFORE analysis
SELECT
    (SELECT COUNT(DISTINCT Product_SKU) FROM inventory_summary_clean)                       AS inventory_skus,
    (SELECT COUNT(DISTINCT Product_SKU) FROM purchase_orders_clean)                        AS po_skus,
    (SELECT COUNT(DISTINCT i.Product_SKU)
       FROM inventory_summary_clean i
       LEFT JOIN purchase_orders_clean p ON p.Product_SKU = i.Product_SKU
      WHERE p.Product_SKU IS NULL)                                                          AS inventory_skus_missing_in_po;

-- ------------------------------------------------------------------------------------
-- 3. MASTER FACT VIEW  (orders + vendor + shipment; one row per PO line)
-- ------------------------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_supply_chain_fact AS
SELECT
    po.PO_ID, po.Vendor_ID, v.Vendor_Name, v.Vendor_Category, v.Country,
    v.Reliability_Score, v.Vendor_Tier, v.Lead_Time_Days,
    po.Product_Category, po.Product_SKU, po.Warehouse_ID,
    po.Order_Date, po.Order_Month, po.Order_Quarter,
    po.Expected_Delivery_Date, po.Actual_Delivery_Date,
    po.Ordered_Quantity, po.Unit_Price_INR, po.Total_Order_Value,
    po.Order_Status, po.Delivery_Delay_Days, po.Late_Delivery,
    s.Shipment_ID, s.Shipment_Mode, s.Carrier_Name, s.Freight_Cost_INR,
    s.Shipment_Weight_KG, s.Transit_Days, s.Damage_Flag
FROM purchase_orders_clean po
LEFT JOIN vendor_master_clean v ON v.Vendor_ID = po.Vendor_ID
LEFT JOIN shipments_clean     s ON s.PO_ID     = po.PO_ID;

/* =====================================================================================
   4. FIFTEEN ANALYTICAL QUERIES
   ===================================================================================== */

-- ----------------------------------------------------------------------------------
-- Q1. OVERALL ON-TIME DELIVERY RATE
-- Business question: Is our delivery performance meeting the 85% industry benchmark?
-- Logic: a delivered order is on-time when Delivery_Delay_Days <= 0. Undelivered
--        orders (Actual_Delivery_Date IS NULL) are excluded from the denominator.
-- ----------------------------------------------------------------------------------
SELECT
    COUNT(*)                                                              AS delivered_orders,
    SUM(CASE WHEN Late_Delivery = 0 THEN 1 ELSE 0 END)                    AS on_time_orders,
    ROUND(100 * SUM(CASE WHEN Late_Delivery = 0 THEN 1 ELSE 0 END) / COUNT(*), 2) AS on_time_rate_pct,
    85                                                                    AS benchmark_pct,
    ROUND(100 * SUM(CASE WHEN Late_Delivery = 0 THEN 1 ELSE 0 END) / COUNT(*) - 85, 2) AS gap_vs_benchmark_pct
FROM purchase_orders_clean
WHERE Actual_Delivery_Date IS NOT NULL;

-- ----------------------------------------------------------------------------------
-- Q2. VENDOR-WISE DELIVERY PERFORMANCE RANKING
-- Business question: Which vendors are causing the most delays?
-- Logic: rank vendors (min 20 delivered orders) by late-delivery rate, worst first.
-- ----------------------------------------------------------------------------------
SELECT
    v.Vendor_ID, v.Vendor_Name, v.Vendor_Category, v.Vendor_Tier, v.Reliability_Score,
    COUNT(*)                                              AS delivered_orders,
    SUM(po.Late_Delivery)                                 AS late_orders,
    ROUND(100 * SUM(po.Late_Delivery) / COUNT(*), 2)      AS late_rate_pct,
    ROUND(AVG(po.Delivery_Delay_Days), 2)                 AS avg_delay_days
FROM purchase_orders_clean po
JOIN vendor_master_clean v ON v.Vendor_ID = po.Vendor_ID
WHERE po.Actual_Delivery_Date IS NOT NULL
GROUP BY v.Vendor_ID, v.Vendor_Name, v.Vendor_Category, v.Vendor_Tier, v.Reliability_Score
HAVING COUNT(*) >= 20
ORDER BY late_rate_pct DESC, avg_delay_days DESC
LIMIT 25;

-- ----------------------------------------------------------------------------------
-- Q3. AVERAGE DELIVERY DELAY BY VENDOR TIER
-- Business question: Are Tier 3 vendors significantly less reliable than Tier 1?
-- Logic: aggregate delay + late-rate by the reliability-score tier.
-- ----------------------------------------------------------------------------------
SELECT
    v.Vendor_Tier,
    COUNT(*)                                          AS delivered_orders,
    ROUND(AVG(po.Delivery_Delay_Days), 2)             AS avg_delay_days,
    ROUND(STDDEV_SAMP(po.Delivery_Delay_Days), 2)     AS stddev_delay_days,
    ROUND(100 * SUM(po.Late_Delivery) / COUNT(*), 2)  AS late_rate_pct
FROM purchase_orders_clean po
JOIN vendor_master_clean v ON v.Vendor_ID = po.Vendor_ID
WHERE po.Actual_Delivery_Date IS NOT NULL
GROUP BY v.Vendor_Tier
ORDER BY FIELD(v.Vendor_Tier,'Tier 1','Tier 2','Tier 3','Unclassified');

-- ----------------------------------------------------------------------------------
-- Q4. TOP 10 VENDORS BY PROCUREMENT SPEND
-- Business question: Where is the highest procurement spend concentrated?
-- Logic: SUM(Total_Order_Value) per vendor + share of the grand total.
-- ----------------------------------------------------------------------------------
SELECT
    v.Vendor_ID, v.Vendor_Name, v.Vendor_Category, v.Country, v.Vendor_Tier,
    COUNT(*)                                    AS orders,
    ROUND(SUM(po.Total_Order_Value), 2)         AS total_spend_inr,
    ROUND(100 * SUM(po.Total_Order_Value) /
          (SELECT SUM(Total_Order_Value) FROM purchase_orders_clean), 2) AS spend_share_pct
FROM purchase_orders_clean po
JOIN vendor_master_clean v ON v.Vendor_ID = po.Vendor_ID
GROUP BY v.Vendor_ID, v.Vendor_Name, v.Vendor_Category, v.Country, v.Vendor_Tier
ORDER BY total_spend_inr DESC
LIMIT 10;

-- ----------------------------------------------------------------------------------
-- Q5. PRODUCT CATEGORY-WISE PROCUREMENT SPEND & SHARE
-- Business question: Which categories consume the most budget?
-- Logic: spend by category with % share via a scalar subquery.
-- ----------------------------------------------------------------------------------
SELECT
    Product_Category,
    COUNT(*)                               AS orders,
    ROUND(SUM(Total_Order_Value), 2)       AS procurement_spend_inr,
    ROUND(100 * SUM(Total_Order_Value) /
          (SELECT SUM(Total_Order_Value) FROM purchase_orders_clean), 2) AS spend_share_pct
FROM purchase_orders_clean
GROUP BY Product_Category
ORDER BY procurement_spend_inr DESC;

-- ----------------------------------------------------------------------------------
-- Q6. INVENTORY STOCKOUT RISK ANALYSIS
-- Business question: Which SKUs across which warehouses are below reorder level?
-- Logic: latest snapshot only; Stock_On_Hand < Reorder_Level; biggest gap first.
-- ----------------------------------------------------------------------------------
SELECT
    Product_SKU, Product_Name, Product_Category, Warehouse_ID, Warehouse_Location,
    Stock_On_Hand, Reorder_Level, Units_Sold_Last_Month,
    (Reorder_Level - Stock_On_Hand)              AS gap_units
FROM inventory_summary_clean
WHERE Stockout_Risk = 1
  AND Snapshot_Date = (SELECT MAX(Snapshot_Date) FROM inventory_summary_clean)
ORDER BY gap_units DESC;
-- Count only:
SELECT COUNT(*) AS stockout_lines_latest_snapshot
FROM inventory_summary_clean
WHERE Stockout_Risk = 1
  AND Snapshot_Date = (SELECT MAX(Snapshot_Date) FROM inventory_summary_clean);

-- ----------------------------------------------------------------------------------
-- Q7. INVENTORY TURNOVER RATE BY CATEGORY
-- Business question: Which product categories have slow-moving stock (turnover < 4x/yr)?
-- Logic: AVG(Inventory_Turnover_Rate) by category; HAVING isolates slow movers.
-- ----------------------------------------------------------------------------------
SELECT
    Product_Category,
    COUNT(*)                                     AS sku_lines,
    ROUND(AVG(Inventory_Turnover_Rate), 2)       AS avg_turnover_x,
    ROUND(AVG(Months_Of_Supply), 2)              AS avg_months_supply,
    CASE WHEN AVG(Inventory_Turnover_Rate) < 4 THEN 'Slow (<4x/yr)' ELSE 'Healthy' END AS movement_flag
FROM inventory_summary_clean
GROUP BY Product_Category
ORDER BY avg_turnover_x ASC;
-- Slow movers only:
SELECT Product_Category, ROUND(AVG(Inventory_Turnover_Rate),2) AS avg_turnover_x
FROM inventory_summary_clean
GROUP BY Product_Category
HAVING AVG(Inventory_Turnover_Rate) < 4;

-- ----------------------------------------------------------------------------------
-- Q8. FREIGHT COST ANALYSIS BY SHIPMENT MODE
-- Business question: Which shipping method has the highest total and average cost?
-- ----------------------------------------------------------------------------------
SELECT
    Shipment_Mode,
    COUNT(*)                             AS shipments,
    ROUND(SUM(Freight_Cost_INR), 2)      AS total_freight_inr,
    ROUND(AVG(Freight_Cost_INR), 2)      AS avg_freight_inr,
    ROUND(AVG(Freight_Cost_Per_KG), 2)   AS avg_cost_per_kg
FROM shipments_clean
GROUP BY Shipment_Mode
ORDER BY total_freight_inr DESC;

-- ----------------------------------------------------------------------------------
-- Q9. MONTHLY SHIPMENT VOLUME & COST TREND
-- Business question: Are logistics volumes and costs growing month-over-month?
-- ----------------------------------------------------------------------------------
SELECT
    DATE_FORMAT(Dispatch_Date, '%Y-%m')  AS ship_month,
    COUNT(*)                             AS shipments,
    ROUND(SUM(Freight_Cost_INR), 2)      AS total_freight_inr,
    ROUND(AVG(Freight_Cost_INR), 2)      AS avg_freight_inr
FROM shipments_clean
WHERE Dispatch_Date IS NOT NULL
GROUP BY DATE_FORMAT(Dispatch_Date, '%Y-%m')
ORDER BY ship_month;

-- ----------------------------------------------------------------------------------
-- Q10. DAMAGED SHIPMENT RATE BY CARRIER
-- Business question: Which carrier has the highest damage rate?
-- ----------------------------------------------------------------------------------
SELECT
    Carrier_Name,
    COUNT(*)                                                            AS shipments,
    SUM(CASE WHEN Damage_Flag = 'Yes' THEN 1 ELSE 0 END)               AS damaged_shipments,
    ROUND(100 * SUM(CASE WHEN Damage_Flag = 'Yes' THEN 1 ELSE 0 END) / COUNT(*), 2) AS damage_rate_pct
FROM shipments_clean
GROUP BY Carrier_Name
ORDER BY damage_rate_pct DESC;

-- ----------------------------------------------------------------------------------
-- Q11. SUPPLIER RETURN VOLUME & VALUE ANALYSIS
-- Business question: Which suppliers have the highest return quantities and values?
-- ----------------------------------------------------------------------------------
SELECT
    v.Vendor_ID, v.Vendor_Name, v.Vendor_Category, v.Vendor_Tier,
    COUNT(*)                              AS return_lines,
    SUM(r.Return_Qty)                     AS total_return_qty,
    ROUND(SUM(r.Return_Value), 2)         AS total_return_value_inr
FROM returns_clean r
JOIN vendor_master_clean v ON v.Vendor_ID = r.Vendor_ID
GROUP BY v.Vendor_ID, v.Vendor_Name, v.Vendor_Category, v.Vendor_Tier
ORDER BY total_return_value_inr DESC
LIMIT 25;

-- ----------------------------------------------------------------------------------
-- Q12. RETURN REASON DISTRIBUTION
-- Business question: What are the primary root causes for returns?
-- ----------------------------------------------------------------------------------
SELECT
    Return_Reason,
    COUNT(*)                             AS return_lines,
    SUM(Return_Qty)                      AS total_return_qty,
    ROUND(SUM(Return_Value), 2)          AS total_return_value_inr,
    ROUND(100 * COUNT(*) / (SELECT COUNT(*) FROM returns_clean), 2) AS line_share_pct
FROM returns_clean
GROUP BY Return_Reason
ORDER BY return_lines DESC;

-- ----------------------------------------------------------------------------------
-- Q13. MONTHLY / QUARTERLY PROCUREMENT VALUE TREND
-- Business question: Is procurement spend increasing quarter-over-quarter?
-- ----------------------------------------------------------------------------------
SELECT
    Order_Quarter,
    COUNT(*)                             AS orders,
    ROUND(SUM(Total_Order_Value), 2)     AS procurement_spend_inr,
    ROUND(SUM(Total_Order_Value) -
          LAG(SUM(Total_Order_Value)) OVER (ORDER BY Order_Quarter), 2) AS qoq_change_inr,
    ROUND(100 * (SUM(Total_Order_Value) /
          LAG(SUM(Total_Order_Value)) OVER (ORDER BY Order_Quarter) - 1), 2) AS qoq_growth_pct
FROM purchase_orders_clean
WHERE Order_Quarter <> ''
GROUP BY Order_Quarter
ORDER BY Order_Quarter;

-- ----------------------------------------------------------------------------------
-- Q14. WAREHOUSE-WISE INVENTORY DISTRIBUTION & RISK PROFILE
-- Business question: Are stocks evenly distributed? Which warehouses carry the most risk?
-- ----------------------------------------------------------------------------------
SELECT
    Warehouse_ID, Warehouse_Location,
    COUNT(*)                                                       AS sku_lines,
    SUM(Stock_On_Hand)                                             AS total_stock_units,
    COUNT(CASE WHEN Stockout_Risk = 1 THEN 1 END)                  AS stockout_lines,
    COUNT(CASE WHEN Overstock_Risk = 1 THEN 1 END)                 AS overstock_lines,
    ROUND(100 * COUNT(CASE WHEN Stockout_Risk = 1 THEN 1 END) / COUNT(*), 2)  AS stockout_rate_pct,
    ROUND(100 * COUNT(CASE WHEN Overstock_Risk = 1 THEN 1 END) / COUNT(*), 2) AS overstock_rate_pct,
    ROUND(AVG(Inventory_Turnover_Rate), 2)                         AS avg_turnover_x
FROM inventory_summary_clean
GROUP BY Warehouse_ID, Warehouse_Location
ORDER BY stockout_rate_pct DESC;

-- ----------------------------------------------------------------------------------
-- Q15. HIGH-RISK VENDOR COMPOSITE SCORECARD
-- Business question: Which vendors have the worst combined profile of low reliability,
--                    high delays and high returns?
-- Logic: LEFT JOIN returns (not every vendor has returns); build a 0-4 risk-point
--        score from four threshold tests; band the result.
-- ----------------------------------------------------------------------------------
WITH po_agg AS (
    SELECT Vendor_ID,
           COUNT(*)                                          AS orders,
           ROUND(100 * SUM(Late_Delivery) / NULLIF(SUM(CASE WHEN Actual_Delivery_Date IS NOT NULL THEN 1 END),0), 2) AS late_rate_pct,
           ROUND(AVG(Delivery_Delay_Days), 2)                AS avg_delay_days,
           ROUND(SUM(Total_Order_Value), 2)                  AS total_spend_inr
    FROM purchase_orders_clean
    GROUP BY Vendor_ID
),
ret_agg AS (
    SELECT Vendor_ID, COUNT(*) AS return_lines, ROUND(SUM(Return_Value),2) AS return_value_inr
    FROM returns_clean GROUP BY Vendor_ID
),
med AS (
    SELECT
      (SELECT AVG(x.late_rate_pct)  FROM (SELECT late_rate_pct FROM po_agg ORDER BY late_rate_pct  LIMIT 2 OFFSET 499) x) AS med_late,
      (SELECT AVG(x.avg_delay_days) FROM (SELECT avg_delay_days FROM po_agg ORDER BY avg_delay_days LIMIT 2 OFFSET 499) x) AS med_delay
)
SELECT
    v.Vendor_ID, v.Vendor_Name, v.Vendor_Category, v.Vendor_Tier, v.Reliability_Score,
    p.orders, p.late_rate_pct, p.avg_delay_days, p.total_spend_inr,
    COALESCE(r.return_lines, 0)                                   AS return_lines,
    COALESCE(r.return_value_inr, 0)                               AS return_value_inr,
    ROUND(100 * COALESCE(r.return_lines,0) / p.orders, 2)         AS return_rate_pct,
    ( (v.Reliability_Score < 60)
    + (p.late_rate_pct > (SELECT med_late  FROM med))
    + (p.avg_delay_days > (SELECT med_delay FROM med))
    + (COALESCE(r.return_lines,0) / p.orders > 0.10) )            AS risk_points,
    CASE
       WHEN ( (v.Reliability_Score < 60)
            + (p.late_rate_pct > (SELECT med_late  FROM med))
            + (p.avg_delay_days > (SELECT med_delay FROM med))
            + (COALESCE(r.return_lines,0) / p.orders > 0.10) ) >= 3 THEN 'High Risk'
       WHEN ( (v.Reliability_Score < 60)
            + (p.late_rate_pct > (SELECT med_late  FROM med))
            + (p.avg_delay_days > (SELECT med_delay FROM med))
            + (COALESCE(r.return_lines,0) / p.orders > 0.10) ) = 2 THEN 'Medium Risk'
       ELSE 'Low Risk'
    END                                                          AS risk_band
FROM vendor_master_clean v
JOIN po_agg  p ON p.Vendor_ID = v.Vendor_ID
LEFT JOIN ret_agg r ON r.Vendor_ID = v.Vendor_ID
WHERE p.orders >= 20
ORDER BY risk_points DESC, p.late_rate_pct DESC
LIMIT 50;

/* ===================================== END OF SCRIPT ================================ */
