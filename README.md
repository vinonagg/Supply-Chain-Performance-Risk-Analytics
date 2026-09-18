# 🚚 Supply Chain Performance & Risk Analytics System

> **End-to-end BI analytics solution for Procurement, Inventory, Logistics, Vendor Management & Returns**

[![MySQL](https://img.shields.io/badge/MySQL-8.0%2B-4479A1?logo=mysql\&logoColor=white)](https://www.mysql.com/)
[![Power BI](https://img.shields.io/badge/Power%20BI-Dashboard-F2C811?logo=powerbi\&logoColor=black)](https://powerbi.microsoft.com/)
[![Excel](https://img.shields.io/badge/Excel-Data%20Preparation-217346?logo=microsoftexcel\&logoColor=white)](https://www.microsoft.com/microsoft-365/excel)
[![SQL](https://img.shields.io/badge/SQL-15%20Analytical%20Queries-336791)](https://www.mysql.com/)
[![Records](https://img.shields.io/badge/Raw%20Records-106K%2B-6f42c1)](#-data-overview)
[![Period](https://img.shields.io/badge/Data%20Window-2021--2024-orange)](#-data-overview)

---

## 📌 Executive Overview

This project delivers a complete **Supply Chain Performance & Risk Analytics System** designed to identify operational inefficiencies, vendor risks, procurement leakage, inventory imbalance, logistics bottlenecks and return drivers.

The solution processes approximately **1.06 lakh raw records across five business datasets**, transforming raw operational data into:

* 📊 Executive-level KPIs
* 🏭 Vendor performance intelligence
* 📦 Inventory risk analytics
* 🚚 Logistics & shipment analytics
* 💰 Procurement spend analysis
* 🔄 Returns & quality analysis
* 🎯 Vendor RFM segmentation
* ⚠️ Composite high-risk vendor scoring
* 🧠 Correlation and statistical analysis
* 🗄️ MySQL analytical data model
* 📈 Four-page BI dashboard
* 🎤 Executive presentation and recommendations

**Data period:** January 2021 – December 2024
**Currency:** INR (₹)
**Raw records:** 106,195
**Core datasets:** 5

---

## 🎯 Decision-Intelligence Portfolio Framing

> **This project transforms operational data into executive KPIs, risk signals and action-oriented insights across vendor management, procurement, inventory, logistics and returns.**

### Why this matters for AI Transformation

AI transformation depends on a strong decision and data foundation. This project demonstrates practical capability in:

- Defining business KPIs and decision metrics
- Validating data quality before automation or AI use
- Segmenting operational risk
- Translating analytics into executive actions
- Building a reproducible path from raw operational data to decision support

### AI / GenAI Roadmap

The current implementation is an analytics and BI solution. Potential future AI extensions include:

- Natural-language querying over supply-chain KPIs
- Automated anomaly detection and alerting
- AI-generated explanations for vendor and inventory risk
- Scenario-based recommendations
- Conversational executive decision support

These items are **future extensions**, not capabilities claimed as already implemented in this repository.

---

## 🧭 Project Navigation

| Section                                               | Description                         |
| ----------------------------------------------------- | ----------------------------------- |
| [🎯 Business Problem](#-business-problem)             | Business context and objectives     |
| [🗂️ Data Overview](#-data-overview)                  | Datasets, records and relationships |
| [🔄 Analytics Architecture](#-analytics-architecture) | End-to-end workflow                 |
| [🧹 Data Preparation](#-data-preparation)             | Cleaning and transformation rules   |
| [📊 KPI Results](#-headline-results)                  | Key business findings               |
| [🧠 Advanced Analytics](#-advanced-analytics)         | RFM and vendor risk scoring         |
| [🗄️ SQL Analytics](#-sql-analytics)                  | MySQL schema and 15 queries         |
| [📈 Dashboard](#-bi-dashboard)                        | Four-page dashboard                 |
| [📁 Repository Structure](#-repository-structure)     | Project files                       |
| [🔁 Rebuild](#-reproducibility)                       | Rebuild the complete project        |
| [💡 Recommendations](#-business-recommendations)      | Recommended actions                 |
| [📦 Deliverables](#-deliverables)                     | Final project outputs               |

---

# 🎯 Business Problem

Manufacturing and distribution organizations operate across a complex network of vendors, purchase orders, inventory locations, warehouses, shipments and customer returns.

The key business challenge addressed by this project is:

> **How can supply chain leaders identify performance gaps and proactively manage vendor, procurement, inventory and logistics risks using data?**

### Key business questions

**Vendor Management**

* Which vendors are reliable?
* Which vendors have persistent delivery delays?
* Which vendors represent the highest operational risk?
* Does vendor reliability actually correlate with delivery performance?

**Procurement**

* Where is procurement spend concentrated?
* Which product categories drive the largest spend?
* Are procurement costs increasing over time?
* Where are potential cost-leakage opportunities?

**Inventory**

* Which SKUs are at stockout risk?
* Which categories or warehouses are overstocked?
* What is the inventory turnover performance?
* Where is working capital potentially trapped?

**Logistics**

* Which shipment modes are most expensive?
* Which carriers experience higher damage rates?
* How long does freight remain in transit?
* How does logistics performance affect supply chain reliability?

**Returns**

* Which return reasons dominate?
* Which suppliers generate higher return rates?
* What portion of returns is associated with quality and packaging issues?

---

# 🗂️ Data Overview

The project uses five operational datasets.

| Dataset               | Raw Records | Business Domain   | Primary Key   |
| --------------------- | ----------: | ----------------- | ------------- |
| `vendor_master_raw`   |       1,015 | Vendor Management | `Vendor_ID`   |
| `purchase_orders_raw` |      50,100 | Procurement       | `PO_ID`       |
| `inventory_raw`       |      30,000 | Inventory         | `SKU`         |
| `shipments_raw`       |      20,000 | Logistics         | `Shipment_ID` |
| `returns_raw`         |       5,080 | Returns           | `Return_ID`   |
| **Total**             | **106,195** | **Supply Chain**  | —             |

### Data period

```text
January 2021 ───────────────────────────── December 2024
```

### Core entities

```text
                    ┌──────────────────┐
                    │   Vendor Master  │
                    │   Vendor_ID      │
                    └────────┬─────────┘
                             │
                             │ Vendor_ID
                             ▼
┌──────────────┐      ┌──────────────────┐
│  Inventory   │      │ Purchase Orders  │
│     SKU      │◄────►│      PO_ID       │
└──────┬───────┘      └────────┬─────────┘
       │                       │
       │ SKU                   │ PO / Vendor
       │                       ▼
       │                ┌───────────────┐
       └───────────────►│  Shipments    │
                        │ Shipment_ID   │
                        └───────┬───────┘
                                │
                                ▼
                        ┌───────────────┐
                        │   Returns     │
                        │   Return_ID   │
                        └───────────────┘
```

> **Important data-quality observation:** the supplied Inventory dataset contains approximately 500 unique SKUs, while Purchase Orders contain approximately 5,000 unique SKUs. This SKU coverage difference was explicitly validated and documented rather than hidden.

---

# 🔄 Analytics Architecture

```text
┌──────────────────────┐
│   RAW DATASETS       │
│                      │
│ Vendor               │
│ Purchase Orders      │
│ Inventory            │
│ Shipments            │
│ Returns              │
└──────────┬───────────┘
           │
           ▼
┌──────────────────────┐
│ DATA QUALITY &       │
│ CLEANING             │
│                      │
│ • Null handling      │
│ • Duplicate removal  │
│ • Date validation    │
│ • Standardization    │
│ • Outlier flags      │
│ • Derived columns    │
└──────────┬───────────┘
           │
           ▼
┌──────────────────────┐
│ CLEANED CSV LAYER    │
│                      │
│ 5 analytical tables  │
└──────────┬───────────┘
           │
           ├──────────────────┐
           ▼                  ▼
┌──────────────────┐   ┌──────────────────┐
│ STATISTICAL      │   │ MYSQL ANALYTICS  │
│ ANALYSIS         │   │                  │
│                  │   │ • Schema         │
│ • Descriptive    │   │ • Fact View      │
│ • Correlation    │   │ • 15 SQL Queries │
│ • RFM            │   │ • Validations    │
└────────┬─────────┘   └────────┬─────────┘
         │                      │
         └──────────┬───────────┘
                    ▼
          ┌───────────────────┐
          │ BI SEMANTIC LAYER │
          └─────────┬─────────┘
                    ▼
          ┌───────────────────┐
          │ 4-PAGE DASHBOARD  │
          │                   │
          │ 1. Executive      │
          │ 2. Vendor         │
          │ 3. Inventory      │
          │ 4. Logistics      │
          └─────────┬─────────┘
                    ▼
          ┌───────────────────┐
          │ EXECUTIVE         │
          │ DECISIONS         │
          │                   │
          │ Risks → Actions   │
          └───────────────────┘
```

---

# 🧹 Data Preparation

The cleaning process applied the project brief's business rules consistently across all five datasets.

### Vendor Master

* Standardized vendor categories
* Standardized countries
* Removed duplicate `Vendor_ID`
* Validated Reliability Score
* Corrected invalid lead times
* Filled missing lead times using category medians
* Created Vendor Tier

### Vendor Tier Logic

| Reliability Score | Tier      |
| ----------------: | --------- |
|              ≥ 80 | 🟢 Tier 1 |
|             60–79 | 🟡 Tier 2 |
|              < 60 | 🔴 Tier 3 |

---

### Purchase Orders

Derived:

```text
Delivery_Delay_Days
Late_Delivery_Flag
Total_Order_Value
```

Validation included:

* Negative quantity removal
* Negative price removal
* Duplicate PO validation
* Order/expected/actual date validation
* Status standardization

---

### Inventory

Derived:

```text
Inventory_Turnover
Stockout_Risk
Overstock_Risk
```

Inventory turnover:

```text
Annualized Turnover
=
Units Sold Last Month × 12
─────────────────────────
Average Stock On Hand
```

---

### Shipments

Derived:

```text
Transit_Days
Month_Start
```

Validation included:

* Freight cost validation
* Dispatch vs delivery date validation
* Shipment mode standardization
* Damage flag standardization

---

### Returns

Derived:

```text
Return_Value
High_Value_Return
```

Validation included:

* Duplicate Return ID removal
* Return reason standardization
* Refund status standardization
* Non-positive return quantity removal

---

<details>
<summary>📋 View cleaned dataset counts</summary>

| Dataset         |    Raw | Cleaned |
| --------------- | -----: | ------: |
| Vendors         |  1,015 |   1,000 |
| Purchase Orders | 50,100 |  49,914 |
| Inventory       | 30,000 |  29,860 |
| Shipments       | 20,000 |  19,950 |
| Returns         |  5,080 |   4,970 |

</details>

---

# 📊 Headline Results

| KPI                          |             Result | Business Interpretation                                        |
| ---------------------------- | -----------------: | -------------------------------------------------------------- |
| 🚚 **On-Time Delivery Rate** |          **44.3%** | 40.7 percentage points below the 85% benchmark                 |
| 💰 **Procurement Spend**     |     **₹31,567 Cr** | 49,914 cleaned purchase orders                                 |
| 🏭 **Vendor Base**           |          **1,000** | Large and fragmented supplier ecosystem                        |
| 📦 **Inventory Turnover**    |   **16.6× / year** | Strong aggregate movement                                      |
| 🔴 **Stockout Rate**         |           **~10%** | Material availability risk                                     |
| 🟠 **Overstock Rate**        |           **~25%** | Working-capital imbalance                                      |
| 🚚 **Shipment Damage Rate**  |          **17.7%** | Significant logistics quality issue                            |
| 🔄 **Return Value**          |        **₹315 Cr** | Material financial impact                                      |
| ⚠️ **High-Risk Vendors**     |            **319** | Vendors meeting composite risk criteria                        |
| 📈 **Reliability ↔ Delay**   | **~0 correlation** | Reliability score is not strongly predictive of delivery delay |

---

## 🚨 Most Important Finding

### On-Time Delivery is the critical performance gap.

```text
85% Benchmark
█████████████████████████████████████████████

44.3% Actual
██████████████████████

Gap = -40.7 percentage points
```

This indicates that supply chain delivery reliability is substantially below the defined business benchmark.

---

# 🧠 Advanced Analytics

## 1️⃣ Vendor RFM Scoring

Vendor performance was scored using an RFM-style framework:

| Dimension     | Interpretation                               |
| ------------- | -------------------------------------------- |
| **Recency**   | How recently the vendor was active           |
| **Frequency** | Number of purchase transactions              |
| **Monetary**  | Procurement value associated with the vendor |

Each dimension receives a **1–5 score**.

```text
RFM Score
   │
   ├── Recency
   ├── Frequency
   └── Monetary
          │
          ▼
     Vendor Segment
```

Segments include:

* 🏆 Champions
* 💎 Loyal
* 🌱 Potential
* ⚠️ At Risk
* 🔴 Lost

---

## 2️⃣ Composite Vendor Risk Score

Vendor risk combines three dimensions:

```text
Risk Score
=
40% × Inverse Reliability
+
30% × Delivery Delay
+
30% × Return Rate
```

This creates a more actionable risk measure than relying solely on the existing vendor reliability score.

### Risk flags

A vendor can be flagged based on:

* Low reliability
* High delivery delay
* High return rate
* Poor overall composite score

**Result: 319 vendors were identified as high-risk under the composite framework.**

---

# 📈 BI Dashboard

The project is structured as a **four-page executive BI dashboard**.

## Page 1 — Executive Overview

### KPIs

* On-Time Delivery %
* Procurement Spend
* Stockout Count
* Average Freight Cost

### Visuals

* Monthly procurement trend
* Procurement spend by category
* Supply chain performance overview

---

## Page 2 — Vendor Performance

### Visuals

* Vendor Tier distribution
* Late delivery rate by tier
* Top 10 vendors by spend
* Average delivery delay
* High-risk vendor scorecard

### Key question

> **Which suppliers require immediate management attention?**

---

## Page 3 — Inventory & Procurement

### Visuals

* Stockout-risk products
* Inventory turnover by category
* Stockout vs overstock by warehouse
* Warehouse inventory distribution

### Key question

> **Where is inventory availability being compromised or working capital being trapped?**

---

## Page 4 — Logistics & Returns

### Visuals

* Freight cost by shipment mode
* Monthly shipment volume
* Damage rate by carrier
* Return reason distribution
* Return rate by supplier

### Key question

> **Where are logistics and product-quality issues generating avoidable costs?**

---

# 🗄️ SQL Analytics

The MySQL layer contains:

* Database schema
* Five cleaned tables
* Import templates
* Validation queries
* SKU consistency checks
* Master supply-chain fact view
* 15 analytical queries

### Example analytical questions

```sql
-- Vendor delivery performance
-- Procurement spend by category
-- Monthly procurement trends
-- Late delivery analysis
-- Inventory turnover
-- Stockout risk
-- Overstock analysis
-- Freight cost analysis
-- Shipment damage rates
-- Return analysis
-- Vendor RFM
-- High-risk vendor scorecard
```

The complete implementation is available in:

`02_SQL/supply_chain_analysis.sql`

---

# 📁 Repository Structure

```text
Supply-Chain-Performance-Risk-Analytics/
│
├── 01_Cleaned_Data/
│   ├── vendor_master_clean.csv
│   ├── purchase_orders_clean.csv
│   ├── inventory_summary_clean.csv
│   ├── shipments_clean.csv
│   └── returns_clean.csv
│
├── 02_SQL/
│   └── supply_chain_analysis.sql
│
├── 03_Dashboard/
│   ├── Dashboard_Build_Specification.md
│   ├── Supply_Chain_Dashboard.html
│   └── dashboard_data/
│
├── 04_Presentation/
│   └── Supply_Chain_Analytics_Presentation.pptx
│
├── 05_Documentation/
│   ├── Executive_Summary.pdf
│   ├── Data_Cleaning_Documentation.md
│   └── Data_Cleaning_and_Statistical_Analysis.xlsx
│
├── 06_Analysis_Results/
│   ├── metrics.json
│   ├── query_01...15_*.csv
│   ├── descriptive_statistics.csv
│   ├── correlation_analysis.csv
│   ├── vendor_rfm.csv
│   ├── null_summary.csv
│   └── cleaning_log.csv
│
├── build/
│   ├── clean.py
│   ├── analyze.py
│   ├── build_workbook.py
│   ├── build_dashboard.py
│   ├── deck.js
│   └── exec_summary.py
│
└── README.md
```

---

# 🔁 Reproducibility

The complete project can be rebuilt from the supplied data using the build pipeline.

### 1. Clean and transform

```bash
python3 build/clean.py
```

### 2. Generate analytics

```bash
python3 build/analyze.py
```

### 3. Build Excel analysis workbook

```bash
python3 build/build_workbook.py
```

### 4. Build offline dashboard

```bash
python3 build/build_dashboard.py
```

### 5. Build presentation

```bash
node build/deck.js
```

### 6. Build executive summary

```bash
python3 build/exec_summary.py
```

---

# 📦 Deliverables

| Deliverable                    | Location               | Status     |
| ------------------------------ | ---------------------- | ---------- |
| 🧹 Cleaned datasets            | `01_Cleaned_Data/`     | ✅ Complete |
| 🗄️ MySQL analytical script    | `02_SQL/`              | ✅ Complete |
| 📊 BI dashboard specification  | `03_Dashboard/`        | ✅ Complete |
| 🌐 Offline dashboard reference | `03_Dashboard/`        | ✅ Complete |
| 🎤 Executive presentation      | `04_Presentation/`     | ✅ Complete |
| 📄 Executive summary           | `05_Documentation/`    | ✅ Complete |
| 📚 Cleaning documentation      | `05_Documentation/`    | ✅ Complete |
| 🧠 Statistical analysis        | `06_Analysis_Results/` | ✅ Complete |
| 🎯 Vendor RFM                  | `06_Analysis_Results/` | ✅ Complete |
| ⚠️ Vendor risk scorecard       | `06_Analysis_Results/` | ✅ Complete |

---

# 💡 Business Recommendations

## 1. Improve On-Time Delivery

With OTD at approximately **44.3% versus an 85% benchmark**, delivery reliability should be treated as the highest-priority supply chain issue.

**Recommended actions:**

* Establish vendor-specific delivery SLAs
* Introduce monthly vendor performance reviews
* Escalate repeated late-delivery vendors
* Create corrective-action plans for Tier 3 suppliers
* Introduce predictive delivery-risk monitoring

---

## 2. Rationalize High-Risk Vendors

The composite risk framework identifies **319 high-risk vendors**.

Recommended approach:

```text
High Risk
    ↓
Root Cause Analysis
    ↓
Corrective Action
    ↓
90-Day Monitoring
    ↓
Retain / Develop / Replace
```

---

## 3. Reduce Inventory Imbalance

The combination of stockout and overstock exposure indicates that the organization needs better inventory allocation rather than simply increasing total inventory.

Focus on:

* Reorder-point optimization
* Warehouse-level redistribution
* Demand forecasting
* Slow-moving inventory reviews
* SKU-level safety-stock optimization

---

## 4. Address Shipment Damage

A **17.7% damage rate** indicates an important logistics-quality opportunity.

Investigate:

* Carrier
* Shipment mode
* Warehouse
* Product category
* Packaging type
* Route
* Vendor

---

## 5. Attack Return Drivers

Approximately **42% of return value is associated with quality/packaging-related reasons**.

This supports targeted interventions across:

```text
Supplier
   ↓
Packaging
   ↓
Warehouse Handling
   ↓
Carrier
   ↓
Customer Return
```

---

# 🎯 Portfolio Skills Demonstrated

This project demonstrates practical capability across:

### Business Intelligence

* KPI design
* Executive dashboards
* Business storytelling
* Root-cause analysis
* Decision-oriented insights

### Data Analytics

* Data profiling
* Data quality validation
* Descriptive statistics
* Correlation analysis
* RFM segmentation
* Composite risk scoring

### SQL

* MySQL
* DDL
* Analytical queries
* Aggregations
* CTEs
* Window functions
* Ranking
* Business KPI calculations
* Analytical views

### BI

* Power BI / Tableau design
* Data modeling
* DAX measure design
* Interactive dashboard architecture
* Executive visualization

### Data Engineering

* Data cleaning
* Derived metrics
* Validation framework
* Reproducible analytical pipeline

---

# 🛠️ Technology Stack

```text
Data Preparation
      │
      ├── Microsoft Excel
      └── Python reproducibility pipeline
              │
              ▼
Database
      │
      └── MySQL
              │
              ▼
Analytics
      │
      ├── SQL
      ├── Statistical Analysis
      ├── RFM
      └── Composite Risk Scoring
              │
              ▼
Visualization
      │
      ├── Power BI
      └── Tableau-compatible specification
              │
              ▼
Communication
      │
      ├── Executive Dashboard
      ├── PowerPoint
      └── Executive Summary
```

---

# 📚 Documentation

Detailed supporting documentation is available inside the repository:

* [`Data Cleaning Documentation`](05_Documentation/Data_Cleaning_Documentation.md)
* [`Dashboard Build Specification`](03_Dashboard/Dashboard_Build_Specification.md)
* [`MySQL Analytical Script`](02_SQL/supply_chain_analysis.sql)
* [`Statistical Analysis Workbook`](05_Documentation/Data_Cleaning_and_Statistical_Analysis.xlsx)

---

# ⚠️ Methodology Note

> **The original project brief mandates Excel-only cleaning.**
>
> For this repository, the same documented business rules were implemented through a scripted reproducibility pipeline so the transformation process is deterministic, auditable and repeatable.
>
> Every cleaning rule is also documented as Excel formulas in the workbook sheet:
>
> `04_Derived_Column_Formulas`
>
> and described in:
>
> `Data_Cleaning_Documentation.md`
>
> This allows the analytical process to be reproduced manually in Excel while also maintaining a reproducible build pipeline.

The production BI design is specified for a **Power BI DirectQuery model against `supply_chain_db`**. The bundled HTML dashboard is an offline reference implementation using the project's actual calculated results.

---

# 🏆 Project Outcome

The final system converts fragmented supply-chain operational data into a structured decision-support framework:

```text
106K+ RAW RECORDS
       │
       ▼
DATA QUALITY
       │
       ▼
5 CLEANED DATASETS
       │
       ▼
MYSQL ANALYTICS
       │
       ▼
15+ BUSINESS ANALYSES
       │
       ▼
RFM + RISK SCORING
       │
       ▼
4-PAGE BI DASHBOARD
       │
       ▼
EXECUTIVE INSIGHTS
       │
       ▼
ACTIONABLE SUPPLY CHAIN DECISIONS
```

### ⭐ The core business message

> **The largest opportunity is not simply increasing supply-chain capacity — it is improving reliability, balancing inventory, controlling logistics quality and proactively managing high-risk vendors.**

---

## 👤 Author

**Vinoth Nagarajan**

BI & Analytics | AI / GenAI | Program & Operations Management

This project demonstrates an end-to-end approach to transforming operational data into **business insights, executive KPIs and actionable decisions**.

---

## ⭐ If you find this project useful

Feel free to explore the SQL queries, dashboard specification, analytical outputs and executive presentation.

**⭐ Star the repository if you find the project useful.**

[⬆ Back to Top](#-supply-chain-performance--risk-analytics-system)

