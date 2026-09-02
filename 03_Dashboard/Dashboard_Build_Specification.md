# Dashboard Build Specification
### Supply Chain Performance & Risk Analytics System — Phase 5

A **4-page interactive dashboard** connected **directly to MySQL `supply_chain_db`** (DirectQuery /
Live connection — no static imports, no hardcoded values). This document is the build sheet for
Power BI; Tableau equivalents are noted in *italics*. An offline reference build with the real
numbers is provided as `Supply_Chain_Dashboard.html` in this folder, and the page-level aggregates
are in `dashboard_data/` for validation.

---

## 1. Connection & model

| Item | Setting |
|---|---|
| Data source | MySQL `supply_chain_db` on localhost:3306 |
| Connectivity | **DirectQuery** (*Tableau: Live*) |
| Tables imported | `vendor_master_clean`, `purchase_orders_clean`, `inventory_summary_clean`, `shipments_clean`, `returns_clean`, `vw_supply_chain_fact` |
| Relationships | `purchase_orders_clean[Vendor_ID]` → `vendor_master_clean[Vendor_ID]` (many-to-one, single)<br>`shipments_clean[PO_ID]` → `purchase_orders_clean[PO_ID]` (many-to-one, single)<br>`returns_clean[Vendor_ID]` → `vendor_master_clean[Vendor_ID]` (many-to-one, single)<br>`returns_clean[PO_ID]` → `purchase_orders_clean[PO_ID]` (many-to-one, single)<br>`inventory_summary_clean[Product_SKU]` ↔ `purchase_orders_clean[Product_SKU]` — **no physical relationship** (many-to-many); keep separate, filter via `Product_Category` / `Warehouse_ID` |
| Date table | `Calendar = CALENDAR(DATE(2021,1,1), DATE(2025,3,31))`, mark as date table, relate to `purchase_orders_clean[Order_Date]` (active) and `shipments_clean[Dispatch_Date]` (inactive, `USERELATIONSHIP`) |

### Global slicers (every page, synced)
`Calendar[Date]` (range) · `vendor_master_clean[Vendor_Category]` · `purchase_orders_clean[Product_Category]` ·
`purchase_orders_clean[Warehouse_ID]` · `vendor_master_clean[Vendor_Tier]`

---

## 2. DAX measures (single measure table `_Measures`)

```DAX
-- Procurement -----------------------------------------------------------------
Total Procurement Spend =
    SUM ( purchase_orders_clean[Total_Order_Value] )

Order Count = DISTINCTCOUNT ( purchase_orders_clean[PO_ID] )

Avg Order Value = DIVIDE ( [Total Procurement Spend], [Order Count] )

Procurement Spend QoQ % =
VAR Cur  = [Total Procurement Spend]
VAR Prev = CALCULATE ( [Total Procurement Spend], DATEADD ( Calendar[Date], -1, QUARTER ) )
RETURN DIVIDE ( Cur - Prev, Prev )

-- Delivery performance ------------------------------------------------------------
Delivered Orders =
    CALCULATE ( [Order Count], NOT ISBLANK ( purchase_orders_clean[Actual_Delivery_Date] ) )

On-Time Orders =
    CALCULATE ( [Order Count],
        NOT ISBLANK ( purchase_orders_clean[Actual_Delivery_Date] ),
        purchase_orders_clean[Late_Delivery] = 0 )

On-Time Delivery Rate =
    DIVIDE ( [On-Time Orders], [Delivered Orders] )

On-Time Target = 0.85          -- benchmark line only; not a filter

On-Time vs Benchmark = [On-Time Delivery Rate] - [On-Time Target]

Late Delivery Rate = 1 - [On-Time Delivery Rate]

Avg Delivery Delay (days) = AVERAGE ( purchase_orders_clean[Delivery_Delay_Days] )

-- Inventory ---------------------------------------------------------------------
Latest Snapshot = MAX ( inventory_summary_clean[Snapshot_Date] )

Stockout SKU Lines =
    CALCULATE ( COUNTROWS ( inventory_summary_clean ),
        inventory_summary_clean[Stockout_Risk] = 1,
        inventory_summary_clean[Snapshot_Date] = [Latest Snapshot] )

Overstock SKU Lines =
    CALCULATE ( COUNTROWS ( inventory_summary_clean ),
        inventory_summary_clean[Overstock_Risk] = 1,
        inventory_summary_clean[Snapshot_Date] = [Latest Snapshot] )

Stockout Rate =
    DIVIDE ( [Stockout SKU Lines],
        CALCULATE ( COUNTROWS ( inventory_summary_clean ),
            inventory_summary_clean[Snapshot_Date] = [Latest Snapshot] ) )

Avg Inventory Turnover = AVERAGE ( inventory_summary_clean[Inventory_Turnover_Rate] )

-- Logistics -------------------------------------------------------------------
Total Freight Cost = SUM ( shipments_clean[Freight_Cost_INR] )
Shipment Count     = DISTINCTCOUNT ( shipments_clean[Shipment_ID] )
Avg Freight Cost   = DIVIDE ( [Total Freight Cost], [Shipment Count] )
Avg Transit Days   = AVERAGE ( shipments_clean[Transit_Days] )
Damage Rate =
    DIVIDE ( CALCULATE ( [Shipment Count], shipments_clean[Damage_Flag] = "Yes" ), [Shipment Count] )

-- Returns ---------------------------------------------------------------------
Return Lines      = DISTINCTCOUNT ( returns_clean[Return_ID] )
Total Return Value = SUM ( returns_clean[Return_Value] )
Return Rate (vs PO) = DIVIDE ( [Return Lines], [Order Count] )

-- Vendor risk ------------------------------------------------------------------
Vendor Late Rate =
    DIVIDE (
        CALCULATE ( COUNTROWS ( purchase_orders_clean ), purchase_orders_clean[Late_Delivery] = 1 ),
        CALCULATE ( COUNTROWS ( purchase_orders_clean ), NOT ISBLANK ( purchase_orders_clean[Actual_Delivery_Date] ) )
    )

Vendor Return Value = [Total Return Value]

High-Risk Vendor Flag =                    -- used in the scorecard visual
VAR Rel   = SELECTEDVALUE ( vendor_master_clean[Reliability_Score] )
VAR LateR = [Vendor Late Rate]
VAR RetR  = [Return Rate (vs PO)]
RETURN IF ( ( IF ( Rel < 60, 1, 0 ) + IF ( LateR > 0.557, 1, 0 ) + IF ( RetR > 0.10, 1, 0 ) ) >= 2,
            "High Risk", "OK" )
```

---

## 3. Page 1 — Executive Supply Chain Overview

| Zone | Visual | Field / Measure | Notes |
|---|---|---|---|
| KPI row | Card | **On-Time Delivery Rate** = `[On-Time Delivery Rate]` | conditional format: red < 0.85; caption "Benchmark 85%" |
| KPI row | Card | **Total Procurement Spend** = `[Total Procurement Spend]` | display units = Billions, ₹ |
| KPI row | Card | **Stockout Count** = `[Stockout SKU Lines]` | subtitle "latest snapshot" |
| KPI row | Card | **Avg Freight Cost / Shipment** = `[Avg Freight Cost]` | ₹, 0 dp |
| Main | Line chart | **Monthly Procurement Trend** — Axis `Calendar[Year-Month]`, Value `[Total Procurement Spend]` | add trend line |
| Main | Bar chart | **Category Spend Distribution** — Axis `purchase_orders_clean[Product_Category]`, Value `[Total Procurement Spend]`, sort desc | data labels = % of total |
| Footer | Line chart | **Quarterly Spend + QoQ %** — Value `[Total Procurement Spend]`, secondary line `[Procurement Spend QoQ %]` | |

*Tableau: KPIs = BANs on a tiled dashboard; trend = dual-axis line; category = sorted bar with % of total table calc.*

## 4. Page 2 — Vendor Performance Analytics

| Visual | Config |
|---|---|
| **Vendor Tier Distribution** (Donut) | Legend `vendor_master_clean[Vendor_Tier]`, Value `DISTINCTCOUNT(Vendor_ID)` |
| **Late Delivery Rate by Vendor** (Bar, Top N = 20) | Axis `Vendor_ID`+`Vendor_Name`, Value `[Vendor Late Rate]`, Top-N filter by measure, reference line at 0.557 (portfolio avg) |
| **Top 10 Vendors by Spend** (Table) | `Vendor_Name`, `Vendor_Category`, `Country`, `Vendor_Tier`, `[Total Procurement Spend]`, `[Order Count]`, spend share % ; sort by spend desc, Top-10 filter |
| **Avg Delay by Vendor Tier** (Clustered bar) | Axis `Vendor_Tier`, Values `[Avg Delivery Delay (days)]`, `[Vendor Late Rate]` |
| **High-Risk Vendor Scorecard** (Table + icons) | `Vendor_Name`, `Reliability_Score`, `[Vendor Late Rate]`, `[Return Rate (vs PO)]`, `[Vendor Return Value]`, `High-Risk Vendor Flag`; filter `High-Risk Vendor Flag = "High Risk"`, sort by `[Vendor Late Rate]` desc |

## 5. Page 3 — Inventory & Procurement Analysis

| Visual | Config |
|---|---|
| **Stockout Risk Products** (Table) | `Product_SKU`, `Product_Name`, `Product_Category`, `Warehouse_ID`, `Stock_On_Hand`, `Reorder_Level`, gap = `Reorder_Level - Stock_On_Hand`; filter `Stockout_Risk = 1` and `Snapshot_Date = [Latest Snapshot]`; sort gap desc |
| **Turnover Rate by Category** (Bar) | Axis `Product_Category`, Value `[Avg Inventory Turnover]`, reference line at 4 (slow-mover threshold) |
| **Overstock vs Stockout by Warehouse** (Grouped bar) | Axis `Warehouse_ID`, Values `[Stockout SKU Lines]`, `[Overstock SKU Lines]` |
| **Warehouse Stock Distribution** (Treemap / map) | Group `Warehouse_Location`, Value `SUM(Stock_On_Hand)` |
| Card strip | `[Avg Inventory Turnover]`, `[Stockout Rate]`, `[Overstock SKU Lines]` |

## 6. Page 4 — Logistics, Shipments & Returns

| Visual | Config |
|---|---|
| **Freight Cost by Mode** (Pie) | Legend `Shipment_Mode`, Value `[Total Freight Cost]` |
| **Monthly Shipment Volume Trend** (Line) | Axis `shipments_clean[Month_Start]`, Value `[Shipment Count]`; secondary `[Total Freight Cost]` |
| **Damage Rate by Carrier** (Bar) | Axis `Carrier_Name`, Value `[Damage Rate]`, sort desc, data labels % |
| **Return Reason Distribution** (Bar) | Axis `Return_Reason`, Value `[Return Lines]`, sort desc; tooltip `[Total Return Value]` |
| **Return Rate by Supplier** (Table) | `Vendor_Name`, `Vendor_Category`, `[Return Lines]`, `SUM(Return_Qty)`, `[Total Return Value]`, `[Return Rate (vs PO)]`; sort return value desc, Top-25 |

---

## 7. Formatting standards
- Theme: neutral slate + single accent (`#2F6DB5`); risk states red `#C0392B` / amber `#E1A100` / green `#1E8E5A`.
- Every visual title states the metric ("Late Delivery Rate by Vendor — Top 20"); no raw field names.
- KPI cards carry the benchmark / prior-period comparison as a subtitle.
- All numbers come from measures — **no typed constants in visuals** (only reference lines: 0.85 on-time, 4.0 turnover).
- Tooltips: add a report-page tooltip for vendor visuals showing tier, reliability, order count, late rate, return value.
- Page navigation buttons top-right; slicer panel left, synced across pages; "Reset filters" bookmark button.
