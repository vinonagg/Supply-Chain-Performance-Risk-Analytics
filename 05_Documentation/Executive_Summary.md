# Executive Summary — Supply Chain Performance & Risk Analytics System

*Diagnostic across 1,05,834 cleaned records (1,000 vendors · 49,914 purchase orders · 30,000 inventory
snapshots · 19,950 shipments · 4,970 returns) · order window Jan 2021 – Dec 2024 · all values INR.*

| On-Time Delivery | Procurement Spend | Shipment Damage | Return Value | Stockout Rate (latest) | Top-10 Vendor Share |
|---|---|---|---|---|---|
| **44.3%** (vs 85%) | **₹31,567 Cr** | **17.7%** | **₹315 Cr** | **9.96%** | **1.5%** |

## Situation
The company runs a low-reliability, high-cost supply chain. Delivery performance is roughly half the
industry benchmark, the vendor base is large and undifferentiated, working capital is trapped in
overstock while service still fails at the margin, and product damage and returns are running at
multiples of normal levels. The current vendor `Reliability_Score` does not explain any of this.

## Key findings (data-referenced)
- **Delivery:** only **44.3%** of 46,848 delivered orders were on time vs the 85% benchmark — a
  40.7-point gap. 55.7% arrived late, on average 6.6 days (up to 30).
- **Vendor scoring is broken:** correlation between `Reliability_Score` and `Delivery_Delay_Days` is
  **r = 0.00**. Tier 1 vendors are late 56.1% of the time; Tier 3, 55.4% — statistically indistinguishable.
- **Spend is fragmented:** ₹31,567 Cr across 1,000 vendors; the top 10 are just **1.5%** of spend and
  all 8 categories sit within 12.3–13.0% — little leverage, high administration cost.
- **Inventory imbalance:** turnover is healthy (16.6×/yr, no slow-moving category), but **24.7%** of
  latest-snapshot SKU-lines are overstocked vs 10.0% in stockout; WH06 Kolkata is worst on stockout at 11.9%.
- **Logistics:** ₹249 Cr freight, near-identical average cost across all modes (<7% spread) and a
  **17.7%** damage rate that is uniform across all 8 carriers — a systemic packaging/handling problem.
- **Returns:** ₹315 Cr on 4,970 lines (9.96% of PO lines); Damaged Packaging, Defective Item and
  Quality Failure together account for ~42% of return lines.

## Top 5 strategic recommendations
1. **Launch a delivery-recovery program.** Contractual OTIF targets + a weekly late-order review for the
   worst 50 vendors; target +25 points of on-time delivery within two quarters.
2. **Rebuild the vendor score on outcomes.** Replace the current rating with an index of actual OTIF,
   defect rate and return rate from `vw_supply_chain_fact`; re-tier vendors quarterly.
3. **Consolidate the supplier tail.** Move the 238 RFM "Dormant/At-Risk" and "Low-Value" vendors
   (₹6,088 Cr) into a smaller set of strategic partners to gain pricing leverage and cut transaction cost.
4. **Right-size inventory.** Cut safety stock where overstocked and tighten reorder points at WH06
   Kolkata and the four next-worst sites; release working capital without lowering service.
5. **Fix packaging and inbound QC.** Fund a packaging redesign and an inbound quality gate to drive the
   damage rate below 10% and cut the quality/packaging share of returns.
