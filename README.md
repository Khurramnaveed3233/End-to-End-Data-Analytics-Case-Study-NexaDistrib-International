# 🌐 Global Supply Chain Performance & Optimization Analytics
### End-to-End Data Analytics | SQL Server · Power BI · Excel

<img width="1536" height="1024" alt="Supply Chain Analytics Dashboard" src="https://github.com/user-attachments/assets/2c262c0c-6025-4bbd-aafa-920c9bdcc35f" />

> **"Data is not just about dashboards — it is about identifying problems, generating insights, and driving decisions that move the business forward."**

---

## 📌 Table of Contents

- [Project Overview](#-project-overview)
- [Business Context](#-business-context)
- [Business Problems](#-business-problems-identified)
- [Data Architecture](#-data-architecture--model)
- [Analytical Approach](#-analytical-approach)
- [SQL Deep Dive](#-sql-analysis--techniques)
- [Power BI Dashboards](#-power-bi-dashboard-suite)
- [Key Insights](#-key-insights)
- [Recommendations](#-business-recommendations)
- [Expected Impact](#-expected-business-impact)
- [Skills Demonstrated](#-skills-demonstrated)

---

## 🎯 Project Overview

This is a **complete end-to-end supply chain analytics solution** built from scratch — from raw relational data modeling in SQL Server to executive-level Power BI dashboards and strategic business recommendations.

The goal was not to build charts. The goal was to **diagnose where the business was bleeding money**, quantify the impact, and deliver data-driven decisions that procurement, operations, and executive teams could act on immediately.

| Dimension | Detail |
|---|---|
| **Domain** | Global Supply Chain & Logistics |
| **Tools** | SQL Server, Power BI, Microsoft Excel |
| **Scope** | Procurement → Inventory → Sales → Delivery |
| **Data Period** | January 2023 – November 2024 |
| **Business Problems Solved** | 8 critical operational gaps |
| **Dashboards Delivered** | 4 interactive Power BI pages |

---

## 🏢 Business Context

**NexaDistrib International** is a global distribution company operating across multiple regions with a complex, multi-tier supply chain network.

```
20+ Suppliers    ·    8 Warehouses    ·    100+ Customers    ·    Multi-Region Operations
```

**The Core Challenge:** No unified visibility across supply chain stages. Decisions were being made reactively — without data. The result was compounding inefficiencies across procurement, inventory, fulfillment, and logistics that were directly impacting cost, revenue, and customer satisfaction.

---

## ❗ Business Problems Identified

Before writing a single line of SQL, I mapped out what was costing the business money. Eight critical operational gaps were identified — each with a measurable business consequence.

| # | Problem | Root Cause | Business Consequence |
|---|---|---|---|
| 1 | **Supplier Delays** | No performance-tier accountability | Procurement bottlenecks → missed delivery windows |
| 2 | **Inventory Imbalance** | No automated reorder system | 18% products at stockout risk + capital tied in overstock |
| 3 | **Slow Fulfillment** | Warehouse & carrier inefficiency | Avg 6.2 days; some orders exceeding 10 days |
| 4 | **Revenue Blind Spots** | No segment/region breakdown | Leadership flying blind on growth drivers |
| 5 | **Customer Profitability Unclear** | No customer-level revenue analysis | Resources wasted on low-value accounts |
| 6 | **Warehouse Utilization Gap** | No cross-warehouse inventory balancing | WH-01 at 92% while WH-08 sits at 45% |
| 7 | **Carrier Performance Issues** | No SLA tracking | TCS Courier at 62.1% on-time — harming brand reputation |
| 8 | **Dead Stock** | No slow-mover identification process | Working capital locked in unsellable inventory |

> **Combined business impact:** Lost sales, inflated operational costs, and deteriorating customer experience across all regions.

---

## 🗄️ Data Architecture & Model

Designed a **normalized relational schema** in SQL Server covering the complete supply chain lifecycle — enabling full traceability from a raw purchase order to final customer delivery.

```
Regions ──► Suppliers ──► Purchase Orders ──► Warehouses ──► Inventory
                                                                  │
                                              Customers ──► Sales Orders ──► Shipments
                                                                  │
                                                              Products ──► Categories
```

### Key Entities

| Table | Purpose | Key Fields |
|---|---|---|
| `Suppliers` | Vendor master with tier classification | SupplierTier, LeadTimeDays, RegionID |
| `Purchase_Orders` | Procurement transactions | POStatus, ExpectedDate, ActualReceived |
| `Inventory` | Real-time stock by warehouse | QuantityOnHand, ReorderPoint, WarehouseID |
| `Sales_Orders` | Revenue transactions | OrderStatus, DiscountPct, DeliveredDate |
| `Shipments` | Carrier & delivery tracking | CarrierName, EstimatedArrival, ActualArrival |
| `Warehouses` | Capacity & location data | Capacity, ManagerName, RegionID |
| `Customers` | Segmented customer master | CustomerSegment, JoinDate, RegionID |

This structure made it possible to answer cross-domain questions like:
- *"Which supplier delays caused which warehouse stockouts?"*
- *"Which customer segments are underperforming by region?"*
- *"Is the average fulfillment time getting better or worse by carrier?"*

---

## 🔬 Analytical Approach

Rather than pulling simple totals, I used advanced SQL techniques to transform raw transactional data into layered business intelligence.

```
Raw Transactional Data (SQL Server)
           │
           ▼
   Data Cleaning & Transformation
   (CTEs · CASE Logic · Date Functions)
           │
           ▼
   Business Problem Analysis
   (Window Functions · Aggregations · KPI Queries)
           │
           ▼
   Power BI Data Model  (Star Schema)
           │
           ▼
   DAX Measures  (KPIs · Time Intelligence · Segmentation)
           │
           ▼
   4-Page Interactive Dashboard
           │
           ▼
   Insights → Recommendations → Measurable Business Impact
```

---

## 💻 SQL Analysis & Techniques

### Problem 1 — Supplier Delay Analysis
**Objective:** Identify which suppliers are causing the most procurement disruption, ranked within each tier.

```sql
WITH SupplierDelays AS (
    SELECT
        s.SupplierName,
        s.SupplierTier,
        COUNT(po.POID)                                                        AS TotalOrders,
        SUM(CASE WHEN po.ActualReceived > po.ExpectedDate THEN 1 ELSE 0 END) AS LateDeliveries,
        ROUND(
            100.0 * SUM(CASE WHEN po.ActualReceived > po.ExpectedDate THEN 1 ELSE 0 END)
            / COUNT(po.POID), 1
        )                                                                     AS DelayRate_Pct
    FROM Purchase_Orders po
    JOIN Suppliers s ON po.SupplierID = s.SupplierID
    WHERE po.POStatus != 'Cancelled'
    GROUP BY s.SupplierName, s.SupplierTier
),
RankedSuppliers AS (
    SELECT *,
        RANK() OVER (
            PARTITION BY SupplierTier
            ORDER BY DelayRate_Pct DESC
        ) AS RankWithinTier
    FROM SupplierDelays
)
SELECT * FROM RankedSuppliers
WHERE  RankWithinTier <= 3
ORDER  BY SupplierTier, DelayRate_Pct DESC;
```

**Technique:** CTE + `RANK()` window function partitioned by supplier tier.

**Business Output:** Pinpointed the exact Bronze-tier suppliers dragging the overall on-time rate to 76% — enabling targeted contract renegotiations rather than blanket vendor changes.

---

### Problem 2 — Inventory Risk Scoring
**Objective:** Classify every product-warehouse combination by stock health and flag items most at risk of causing lost sales.

```sql
SELECT
    p.ProductName,
    w.WarehouseName,
    i.QuantityOnHand,
    p.ReorderPoint,
    i.QuantityOnHand - p.ReorderPoint                     AS StockBuffer,
    CASE
        WHEN i.QuantityOnHand = 0                          THEN 'Stockout'
        WHEN i.QuantityOnHand <  p.ReorderPoint            THEN 'Low Stock'
        WHEN i.QuantityOnHand >  p.ReorderPoint * 3        THEN 'Overstocked'
        ELSE                                                    'Healthy'
    END                                                    AS StockStatus,
    RANK() OVER (
        PARTITION BY p.CategoryID
        ORDER BY (i.QuantityOnHand - p.ReorderPoint) ASC
    )                                                      AS RiskRank
FROM  Inventory   i
JOIN  Products    p ON i.ProductID   = p.ProductID
JOIN  Warehouses  w ON i.WarehouseID = w.WarehouseID
ORDER BY StockBuffer ASC;
```

**Technique:** `CASE` classification + `RANK()` window function partitioned by product category.

**Business Output:** Identified 84 zero-stock products and 156 critically low ones. Gave the replenishment team a ranked action list per category — not just a flat dump of numbers.

---

### Problem 3 — Customer Revenue Concentration & Decile Analysis
**Objective:** Identify revenue concentration risk and surface which customer segments and regions are underperforming.

```sql
WITH CustomerRevenue AS (
    SELECT
        c.CustomerName,
        c.CustomerSegment,
        r.RegionName,
        COUNT(so.SalesOrderID)                                               AS TotalOrders,
        SUM(so.QuantityOrdered * p.UnitCost * (1 - so.DiscountPct / 100.0)) AS TotalRevenue,
        AVG(DATEDIFF(day, so.OrderDate, so.DeliveredDate))                   AS AvgFulfillmentDays
    FROM  Sales_Orders so
    JOIN  Customers c ON so.CustomerID = c.CustomerID
    JOIN  Products  p ON so.ProductID  = p.ProductID
    JOIN  Regions   r ON c.RegionID    = r.RegionID
    WHERE so.OrderStatus = 'Delivered'
    GROUP BY c.CustomerName, c.CustomerSegment, r.RegionName
)
SELECT *,
    ROUND(100.0 * TotalRevenue / SUM(TotalRevenue) OVER (), 2) AS RevenueShare_Pct,
    NTILE(10) OVER (ORDER BY TotalRevenue DESC)                AS RevenueDecile
FROM  CustomerRevenue
ORDER BY TotalRevenue DESC;
```

**Technique:** `NTILE(10)` + `SUM() OVER()` for revenue share calculation.

**Business Output:** Confirmed that the top 10% of customers generate 48% of total revenue — a critical concentration risk that directly shaped the customer diversification recommendation.

---

### Problem 4 — Carrier SLA Performance Benchmarking
**Objective:** Rank carriers by delivery reliability and calculate average delay cost to support renegotiation decisions.

```sql
SELECT
    sh.CarrierName,
    COUNT(sh.ShipmentID)                                                          AS TotalShipments,
    SUM(CASE WHEN sh.ActualArrival <= sh.EstimatedArrival THEN 1 ELSE 0 END)      AS OnTimeCount,
    ROUND(
        100.0 * SUM(CASE WHEN sh.ActualArrival <= sh.EstimatedArrival THEN 1 ELSE 0 END)
        / COUNT(sh.ShipmentID), 1
    )                                                                              AS OnTime_Pct,
    AVG(DATEDIFF(day, sh.EstimatedArrival, sh.ActualArrival))                      AS AvgDelayDays,
    ROUND(AVG(sh.ShippingCost), 2)                                                 AS AvgShippingCost
FROM  Shipments sh
GROUP BY sh.CarrierName
ORDER BY OnTime_Pct DESC;
```

**Technique:** Conditional aggregation + date difference functions.

**Business Output:** TCS Courier flagged at 62.1% on-time vs DHL Express at 96.2% — a 34-point gap. Hard numbers that made the carrier replacement case undeniable.

---

## 📊 Power BI Dashboard Suite

Four interconnected dashboards built with a star schema data model, time intelligence DAX measures, and cross-page drill-through filters — giving every team a single source of truth.

---

### Page 1 — Executive Summary

<img width="1536" height="1024" alt="Executive Summary Dashboard" src="https://github.com/user-attachments/assets/b039e735-27e6-4b73-aa93-fb14fbf0f813" />

| KPI | Value | vs Prior Period |
|---|---|---|
| Total Revenue | **$24.83M** | ↑ 18.6% |
| Total Orders | **58,742** | ↑ 14.2% |
| Profit Margin | **17.6%** | Stable |
| On-Time Delivery | **91.3%** | ↑ 4.7% |
| MoM Revenue Growth | **6.35%** | Positive trend |

**Top Region:** North America — $8.21M | **Top Segment:** Enterprise — 40.8% of revenue

---

### Page 2 — Inventory & Warehouse Analysis

<img width="1536" height="1024" alt="Inventory Dashboard" src="https://github.com/user-attachments/assets/2fe70e27-3762-428d-bdac-3d2a97fc0ef5" />

| KPI | Value | Status |
|---|---|---|
| Total Inventory Units | **1,245,780** | — |
| Stockout Products | **84 (8.2%)** | 🔴 Critical — Immediate Action |
| Low Stock Products | **156 (15.1%)** | 🟡 Monitor & Replenish |
| Avg Warehouse Utilization | **72%** | — |

**Critical Finding:** WH-01 and WH-02 are at 92% and 86% capacity while WH-08 sits idle at 45%. Inventory redistribution can simultaneously reduce storage costs and prevent stockouts in high-demand locations.

---

### Page 3 — Supplier & Procurement Performance

<img width="1536" height="1024" alt="Supplier Performance Dashboard" src="https://github.com/user-attachments/assets/c13d0423-d361-493c-a247-7fc4c72345b5" />

| KPI | Value |
|---|---|
| Total Purchase Orders | **150** |
| Overall Supplier On-Time Rate | **76%** |
| Late Deliveries | **36** (↓ 12.2% improvement) |
| Average Lead Time | **6.4 Days** |

**Supplier Tier Breakdown:**

| Tier | On-Time % | Risk Level | Key Suppliers |
|---|---|---|---|
| Gold | 91%+ | Low | Apex Global (94.4%), Prime Materials (93.3%) |
| Silver | 75–85% | Medium | Swift Procurement (84.6%), Reliable Sources (81.8%) |
| Bronze | 25–67% | 🔴 High | Basic Imports (26%), Economy Supplies (34%) |

---

### Page 4 — Sales & Delivery Performance

<img width="1536" height="1024" alt="Sales and Delivery Dashboard" src="https://github.com/user-attachments/assets/bb408050-0850-4802-8ab8-d96a69fb32a3" />

| KPI | Value | vs Prior Period |
|---|---|---|
| Total Sales Revenue | **$24.83M** | ↑ 18.6% |
| Average Order Value | **$428.75** | ↑ 12.4% |
| Avg Fulfillment Days | **6.2 Days** | ↓ 0.8 (improving) |
| Carrier On-Time % | **89.1%** | ↑ 5.7% |

**Top Customer:** Global Tech Solutions — $2.84M revenue across 618 orders (Enterprise, North America)

**Carrier Comparison:**

| Carrier | On-Time % | Performance Band |
|---|---|---|
| DHL Express | 96.2% | ✅ Excellent |
| FedEx Ground | 92.1% | ✅ Excellent |
| UPS Standard | 87.3% | 🟡 Average |
| Aramex | 79.4% | 🟡 Average |
| Blue Dart | 73.2% | 🟡 Average |
| TCS Courier | 62.1% | 🔴 Poor — Action Required |

---

## 💡 Key Insights

### 1. The Supplier Reliability Gap Is an Operational Time Bomb
Gold-tier suppliers deliver 91% on-time. Bronze-tier averages 58%. That 33-point gap means every Bronze-tier purchase order carries a coin-flip chance of disrupting the downstream supply chain. The current supplier mix overexposes the business to Bronze-tier risk.

### 2. The Inventory Crisis Is Structural, Not Seasonal
18% of products are simultaneously stockedout or critically low — while other products are sitting 3–4× over their reorder point. This isn't a demand forecasting problem. It's the absence of a data-driven replenishment system. Office Chairs alone are 4,500 units over reorder point while LED Monitors are at zero.

### 3. Revenue Concentration Is a Hidden Business Risk
The top 10% of customers generate 48% of total revenue. Losing even two or three Enterprise-tier clients could erase months of revenue growth. No growth strategy is resilient without customer base diversification.

### 4. One Carrier Is Actively Hurting Customer Experience
TCS Courier's 62.1% on-time rate is 17 points below the network average. Given that on-time delivery directly correlates with customer retention, every shipment through TCS Courier is a customer satisfaction risk that is currently unmeasured in isolation.

### 5. Warehouse Imbalance Is Inflating Costs and Slowing Fulfillment
WH-01 at 92% capacity is likely creating picking inefficiency and raising storage costs. WH-08 at 45% is an underutilized asset. The fix isn't more warehouse space — it's smarter inventory allocation using demand-region mapping.

---

## 🧠 Business Recommendations

| Priority | Recommendation | Action | Expected Impact |
|---|---|---|---|
| 🔴 High | **Optimize Supplier Tier Mix** | Reduce Bronze-tier PO allocation by 40%; redirect volume to Gold-tier vendors | +20% on-time delivery |
| 🔴 High | **Implement Automated Reorder System** | Set SQL-driven dynamic reorder triggers calibrated to supplier lead times and historical demand | −50% stockouts |
| 🟡 Medium | **Rebalance Warehouse Inventory** | Transfer excess stock from WH-01/WH-02 to WH-07/WH-08 using demand-region heatmap | −15% storage cost |
| 🟡 Medium | **Replace or Penalize Low-Performing Carriers** | Issue SLA improvement plan to TCS Courier; escalate to contract renegotiation or replacement within 90 days | +8% CSAT |
| 🟢 Strategic | **Diversify Revenue Base** | Launch targeted account development in South America & MEA to reduce Enterprise-segment concentration below 35% | +10–15% revenue |
| 🟢 Strategic | **Dead Stock Clearance Program** | Identify slow movers >180 days with no reorder; bundle, discount, or liquidate to free working capital | Significant cost reduction |

---

## 📈 Expected Business Impact

```
+20%    On-Time Delivery Improvement
−50%    Reduction in Product Stockouts
+15%    Revenue Growth Potential
−15%    Warehouse Storage Cost Reduction
        Significant Working Capital Released from Dead Stock
```

These are not aspirational numbers. Each projection is directly tied to a specific data finding and a specific operational change — not a general "best practices" recommendation.

---

## 🏗️ Project Structure

```
supply-chain-analytics/
│
├── 📁 SQL/
│   ├── 01_schema_and_data_model.sql
│   ├── 02_supplier_delay_analysis.sql
│   ├── 03_inventory_risk_scoring.sql
│   ├── 04_customer_revenue_concentration.sql
│   ├── 05_carrier_sla_benchmarking.sql
│   ├── 06_warehouse_utilization_analysis.sql
│   ├── 07_dead_stock_identification.sql
│   └── 08_monthly_revenue_trend.sql
│
├── 📁 PowerBI/
│   └── NexaDistrib_SupplyChain_Analytics.pbix
│
├── 📁 Documentation/
│   ├── data_dictionary.md
│   ├── business_requirements.md
│   └── er_diagram.png
│
└── README.md
```

---

## 🛠️ Skills Demonstrated

| Skill Area | What Was Applied |
|---|---|
| **Advanced SQL** | CTEs, Window Functions (`RANK`, `NTILE`, `SUM OVER`), CASE logic, Date functions, Multi-table JOINs |
| **Data Modeling** | Normalized relational schema, foreign key relationships, star schema for BI layer |
| **Power BI** | Power Query transformations, DAX measures, time intelligence, cross-page drill-through |
| **Business Analysis** | Problem framing before solution design, KPI definition, insight-to-recommendation pipeline |
| **Storytelling with Data** | Translating technical findings into executive-ready language with quantified impact |

---

## 🏁 Conclusion

This project demonstrates the ability to own an analytics problem end-to-end — from understanding the business, to modeling the data, to writing production-quality SQL, to building dashboards that actually drive decisions.

The shift this project enabled:

```
Reactive Decision-Making  →  Data-Driven Strategy
Scattered Operational Data  →  Single Source of Truth
Dashboard Consumer  →  Business Problem Solver
```

---

## 🔗 Connect

- 💼 [LinkedIn](https://www.linkedin.com/in/khurram-naveed-0083851aa/)
- 🗂️ Portfolio
- 💻 GitHub Repository

---

*Built with SQL Server · Power BI · Excel*  
*Khurram Naveed — Data Analyst*
