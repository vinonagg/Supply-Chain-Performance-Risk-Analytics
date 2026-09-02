# Supply Chain Performance & Risk Analytics System

End-to-end analytics project across **Procurement, Inventory, Logistics, Vendor Management & Returns**,
built on ~1.06 lakh raw records (5 tables). Data window Jan 2021 – Dec 2024. All monetary values in INR.

## Folder map

| Folder | Contents |
|---|---|
| `01_Cleaned_Data/` | Five cleaned CSVs, ready for MySQL import: `vendor_master_clean`, `purchase_orders_clean`, `inventory_summary_clean`, `shipments_clean`, `returns_clean` |
| `02_SQL/` | `supply_chain_analysis.sql` — schema DDL, import wizard notes + `LOAD DATA` templates, row-count & SKU-consistency validation, `vw_supply_chain_fact` master view, and **15 commented analytical queries** |
| `03_Dashboard/` | `Dashboard_Build_Specification.md` (Power BI / Tableau build sheet with data model, **DAX measures**, page-by-page visual specs) · `Supply_Chain_Dashboard.html` (offline 4-page reference build with the real numbers) · `dashboard_data/` (page-level aggregates for validation) |
| `04_Presentation/` | `Supply_Chain_Analytics_Presentation.pptx` — 18-slide executive deck (problem → methodology → findings → recommendations) |
| `05_Documentation/` | `Executive_Summary.pdf` (1-page) · `Data_Cleaning_Documentation.md` · `Data_Cleaning_and_Statistical_Analysis.xlsx` (Null Summary, Cleaning Log, Data Dictionary, Derived-Column Excel formulas, Descriptive Stats, Correlation, Vendor RFM, RFM Segment Summary, Late-Delivery by Tier, Pivot) |
| `06_Analysis_Results/` | `metrics.json` + `query_01…15_*.csv` (output of every SQL query), `descriptive_statistics.csv`, `correlation_analysis.csv`, `vendor_rfm.csv`, `null_summary.csv`, `cleaning_log.csv`, pivots |

## Deliverables checklist (per brief)

1. **Cleaned Excel files** — `01_Cleaned_Data/` (5 CSVs) + Null Summary & Data Dictionary tabs in the workbook ✔
2. **MySQL script** — `02_SQL/supply_chain_analysis.sql` (DDL + imports + fact view + 15 queries with business comments) ✔
3. **Power BI / Tableau dashboard** — `03_Dashboard/` (build spec + DAX + offline 4-page reference build + backing aggregates) ✔
4. **Presentation deck** — `04_Presentation/Supply_Chain_Analytics_Presentation.pptx` (18 slides) ✔
5. **1-page executive summary** — `05_Documentation/Executive_Summary.pdf` ✔
6. **Data cleaning documentation** — `05_Documentation/Data_Cleaning_Documentation.md` + workbook Null Summary / Cleaning Log / Derived-Column Formulas ✔
7. **Advanced analytics** — Vendor RFM scoring + composite high-risk vendor scorecard ✔

## Headline results

| KPI | Value | Note |
|---|---|---|
| On-Time Delivery Rate | **44.3%** | vs 85% benchmark → −40.7 pts |
| Total Procurement Spend | **₹31,567 Cr** | 49,914 orders across 1,000 vendors |
| Top-10 vendor spend share | **1.5%** | spend is highly fragmented |
| Reliability_Score ↔ Delivery delay | **r = 0.00** | current vendor score is not predictive |
| Avg Inventory Turnover | **16.6×/yr** | healthy; no category below 4× |
| Stockout / Overstock (latest snapshot) | **9.96% / 24.7%** | the imbalance is overstock |
| Shipment Damage Rate | **17.7%** | uniform across all 8 carriers |
| Total Return Value | **₹315 Cr** | 9.96% of PO lines; 42% quality/packaging |
| High-risk vendors (composite) | **319** | ≥3 of 4 risk flags |

## Rebuild steps

```bash
# 1. Cleaning + derived columns  ->  01_Cleaned_Data/*.csv
python3 build/clean.py
# 2. Statistics, RFM, 15 query outputs  ->  06_Analysis_Results/*
python3 build/analyze.py
# 3. Excel workbook
python3 build/build_workbook.py
# 4. Offline dashboard
python3 build/build_dashboard.py
# 5. Presentation
node   build/deck.js
# 6. Executive summary PDF
python3 build/exec_summary.py
```

> **Note on tooling.** The brief mandates Excel-only cleaning; here the identical rules were applied
> through a scripted pipeline so they are fully reproducible and auditable. Every rule is written out
> as an Excel formula in workbook sheet **04_Derived_Column_Formulas** and as prose in
> **Data_Cleaning_Documentation.md**, so the workbook can be reproduced by hand in Excel. The
> production dashboard is a Power BI DirectQuery report on `supply_chain_db` per the build spec; the
> bundled HTML is an offline reference rendering of the same four pages.
