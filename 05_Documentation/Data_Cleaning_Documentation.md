# Data Cleaning Documentation
### Supply Chain Performance & Risk Analytics System — Phase 2

**Tool:** Microsoft Excel (Power Query + worksheet formulas). No Python / programming used for
transformation logic. Every rule below is reproducible from the formulas in
`Data_Cleaning_and_Statistical_Analysis.xlsx` → sheets **02_Cleaning_Decisions_Log** and
**04_Derived_Column_Formulas**.
**Currency:** all monetary values in INR. **Analysis as-of date:** 2024-12-31 (latest `Order_Date`).

---

## 1. Row-count reconciliation (raw → cleaned)

| Table | Raw rows | Cleaned rows | Removed | Reason |
|---|--:|--:|--:|---|
| vendor_master | 1,015 | **1,000** | 15 | Exact-duplicate `Vendor_ID` records |
| purchase_orders | 50,100 | **49,914** | 186 | 100 duplicate `PO_ID` + 86 rows with negative `Ordered_Quantity` or `Unit_Price_INR` |
| inventory | 30,000 | **30,000** | 0 | Negatives/nulls repaired in place (median imputation) — no rows dropped |
| shipments | 20,000 | **19,950** | 50 | Rows with negative `Freight_Cost_INR` |
| returns | 5,080 | **4,970** | 110 | 80 duplicate `Return_ID` + 30 rows with zero/negative `Return_Qty` |
| **Total** | **1,06,195** | **1,05,834** | **361** | |

---

## 2. Null Summary Table (raw files)

Full table with per-column counts, % and planned action is in workbook sheet **01_Null_Summary**.
Highlights:

| Table | Column | Nulls | % | Action |
|---|---|--:|--:|---|
| vendor_master | Vendor_Category | 35 | 3.45% | Standardize 44 variants → 8 categories; residual blank → `Unknown` |
| vendor_master | Country | 29 | 2.86% | Standardize 30 variants → 10 countries; residual blank → `Unknown` |
| vendor_master | Lead_Time_Days | 29 | 2.86% | Negatives → NULL, then impute with **Vendor_Category median** |
| vendor_master | Contact_Email | 45 | 4.43% | `Not Provided` |
| vendor_master | Active_Since_Year | 38 | 3.74% | Leave NULL (not used in KPIs) |
| purchase_orders | Actual_Delivery_Date | 2,996 | 5.98% | Legitimate (undelivered) — keep NULL |
| purchase_orders | Order_Status | 1,503 | 3.00% | Standardize 27 variants → 5 statuses; blank → `Unknown` |
| purchase_orders | Order_Date | 51 | 0.10% | Leave NULL (unrecoverable); excluded from date-trend queries |
| inventory | Units_Sold_Last_Month | 200 | 0.67% | Impute with **Product_Category median** |
| inventory | Supplier_Lead_Time_Days | 150 | 0.50% | Impute with **Product_Category median** |
| inventory | Stock_On_Hand | 80 | 0.27% | Negatives → NULL, then impute with **Product_Category median** |
| shipments | Shipment_Mode | 637 | 3.18% | Standardize 27 variants → 4 modes; blank → `Unknown` |
| shipments | Delivered_Date | 400 | 2.00% | Legitimate (in transit) — keep NULL |
| shipments | Damage_Flag | 401 | 2.00% | Standardize; blank → `No` (no damage report on file) |
| returns | Approved_By | 1,222 | 24.06% | `Unassigned` (non-analytical field) |
| returns | Return_Reason | 206 | 4.06% | Standardize 38 variants → 7 reasons; blank → `Unknown` |
| returns | Refund_Status | 107 | 2.11% | Standardize 13 variants → 3 statuses; blank → `Unknown` |

---

## 3. Cleaning decisions log (by table)

### 3.1 vendor_master → `vendor_master_clean.csv`
1. **Duplicates** — removed 15 exact-duplicate `Vendor_ID` rows (kept first). 1,015 → 1,000.
2. **Vendor_Category** — mapping table collapses 44 raw variants to 8 canonical values
   (`raw mat`,`Raw Mat`,`rawmaterial` → **Raw Material**; `IT Srvcs`,`Information Technology` → **IT Services**;
   `Electrnics`,`Elect.` → **Electronics**; etc.). 35 residual blanks → `Unknown`.
3. **Country** — 30 raw variants → 10 canonical (`IND`,`Iindia` → **India**; `CHN`,`Chian` → **China**;
   `US`,`U.S.A`,`United States` → **USA**; `Jpn`,`Jappan` → **Japan**; `Germnay` → **Germany**). Blank → `Unknown`.
4. **Reliability_Score** — 11 negative + 9 above 100 (max 999). Flagged in `Reliability_Score_Flag`
   (`Valid` / `Out of Range (0-100)`); out-of-range values set to NULL so they do not distort tiering/means.
5. **Lead_Time_Days** — 7 negatives set to NULL; all 29+7 NULLs imputed with the **median lead time of the
   vendor's category** (overall median as fallback).
6. **Vendor_Tier** (derived) — `Tier 1` ≥ 80, `Tier 2` 60–79, `Tier 3` < 60, `Unclassified` when score is NULL.
   Result: Tier 1 = 269, Tier 2 = 272, Tier 3 = 439, Unclassified = 20.
7. Contact_Email blank → `Not Provided`; Active_Since_Year left NULL.

### 3.2 purchase_orders → `purchase_orders_clean.csv`
1. **Duplicates** — removed 100 duplicate `PO_ID` rows.
2. **Order_Status** — 27 raw variants (`recv`,`Recieved`,`Recvd`,`RECEIVED` → **Received**;
   `pend`,`Pendig` → **Pending**; `intransit`,`In-Transit` → **In Transit**; `part recv`,`Partial` →
   **Partially Received**; `Canceled`,`canceld` → **Cancelled**). 1,503 blanks → `Unknown`.
3. **Negative values** — removed 46 rows with negative `Ordered_Quantity` and 40 rows with negative
   `Unit_Price_INR` (86 rows total).
4. **Date logic** — 80 rows where `Actual_Delivery_Date` < `Order_Date`: the invalid
   `Actual_Delivery_Date` was set to NULL (order row retained). 51 NULL `Order_Date` left as-is.
5. **Derived columns**
   - `Total_Order_Value` = `Ordered_Quantity` × `Unit_Price_INR`
   - `Delivery_Delay_Days` = `Actual_Delivery_Date` − `Expected_Delivery_Date` (negative = early)
   - `Late_Delivery` = 1 when `Delivery_Delay_Days` > 0, else 0 (NULL when undelivered)
   - `Order_Month` (`YYYY-MM`), `Order_Quarter` (`YYYYQn`)

### 3.3 inventory → `inventory_summary_clean.csv`
1. **Stock_On_Hand** — 60 negatives set to NULL; 80+60 NULLs imputed with **Product_Category median**.
2. **Units_Sold_Last_Month** (200 NULL) and **Supplier_Lead_Time_Days** (150 NULL) imputed with
   **Product_Category median**.
3. **SKU consistency** — validated `Product_SKU` against `purchase_orders_clean`: **500 / 500** stocked SKUs
   are present in Purchase Orders (0 orphans). `SKU_In_Purchase_Orders` flag added. Purchase Orders contains
   4,999 distinct SKUs (SKU1000–SKU5999); the inventory snapshot samples 500 of them across 10 warehouses ×
   6 bi-monthly snapshots = 30,000 rows.
4. **Derived columns**
   - `Inventory_Turnover_Rate` = (`Units_Sold_Last_Month` × 12) / `Avg_Stock_On_Hand`
   - `Months_Of_Supply` = `Stock_On_Hand` / `Units_Sold_Last_Month`
   - `Stockout_Risk` = 1 when `Stock_On_Hand` < `Reorder_Level`
   - `Overstock_Risk` = 1 when `Stock_On_Hand` > 2 × `Avg_Stock_On_Hand`

### 3.4 shipments → `shipments_clean.csv`
1. **Shipment_Mode** — 27 raw variants → 4 canonical (`Truck`,`By Road`,`ROAD` → **Road**;
   `Railway`,`RAIL` → **Rail**; `Airfreight`,`AIRFRIEGHT`,`Air Freight` → **Air**;
   `Ocean`,`Sea Freight`,`OCEAN` → **Sea**). 637 blanks → `Unknown`.
2. **Freight_Cost_INR** — removed 50 rows with negative freight cost.
3. **Date logic** — 59 rows where `Delivered_Date` < `Dispatch_Date`: `Delivered_Date` set to NULL.
4. **Damage_Flag** — `Yes/Y/yes/YES` → **Yes**; `No/N/no/NO` → **No**; 401 blanks → **No**.
5. **Derived columns** — `Transit_Days` = `Delivered_Date` − `Dispatch_Date`;
   `Month_Start` = first day of dispatch month; `Freight_Cost_Per_KG` = `Freight_Cost_INR` / `Shipment_Weight_KG`.

### 3.5 returns → `returns_clean.csv`
1. **Duplicates** — removed 80 exact-duplicate `Return_ID` rows.
2. **Return_Qty** — removed 30 rows with zero or negative quantity.
3. **Return_Reason** — 38 raw variants → 7 canonical (`defect`,`DEFECT`,`Defective` → **Defective Item**;
   `qc fail`,`QUALITY FAIL` → **Quality Failure**; `Dmg Packaging`,`damaged pkg`,`Dmgd Pkg` → **Damaged Packaging**;
   `expiry`,`EXPIRED` → **Expired Product**; `over shipment`,`Over Shipment` → **Overshipment**;
   `WRONG QTY`,`wrng qty` → **Wrong Quantity**; `Wrong Item`,`WRONG ITEM` → **Wrong Item Delivered**).
   206 blanks → `Unknown`.
4. **Refund_Status** — `Process` → **Processed**, `pend` → **Pending**, `reject` → **Rejected**; 107 blanks → `Unknown`.
5. **Approved_By** — 1,222 blanks → `Unassigned`.
6. **Derived columns** — `Return_Value` = `Return_Qty` × `Unit_Price_INR`;
   `High_Value_Return` = 1 when `Return_Value` ≥ 90th percentile (≈ ₹14.7 lakh); `Return_Month` (`YYYY-MM`).

---

## 4. Referential integrity (post-clean)

| Check | Result |
|---|---|
| `purchase_orders.Vendor_ID` → `vendor_master` | 0 orphans |
| `shipments.PO_ID` → `purchase_orders` | 0 orphans |
| `returns.PO_ID` → `purchase_orders` | 0 orphans |
| `returns.Vendor_ID` → `vendor_master` | 0 orphans |
| `inventory.Product_SKU` → `purchase_orders.Product_SKU` | 0 orphans (500/500) |

---

## 5. Assumptions & notes
- **Overstock threshold** — `Stock_On_Hand > 2 × Avg_Stock_On_Hand` (no threshold given in the brief; a
  conservative "twice the operating average" rule is used and documented).
- **On-time definition** — an order is on-time when `Delivery_Delay_Days ≤ 0` (Actual not after Expected).
  Undelivered orders are excluded from the rate denominator.
- **RFM recency** — measured in months from each vendor's last `Order_Date` to the as-of date 2024-12-31.
- **Blank vs NULL** — empty strings in the raw CSVs are treated as NULL before any rule is applied.
- Files are UTF-8, comma-delimited, header row retained, ready for the MySQL Table Data Import Wizard.
