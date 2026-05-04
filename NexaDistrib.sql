create database NexaDistrib ; 

use NexaDistrib

--- Analysis 1: Supplier On-Time Delivery Performance 

USE SupplyChainDB;

-- Calculate supplier on-time delivery percentage
SELECT 
    s.SupplierID,
    s.SupplierName,

    COUNT(po.POID) AS TotalOrders,

    SUM(CASE 
        WHEN po.ActualReceived <= po.ExpectedDate THEN 1 
        ELSE 0 
    END) AS OnTimeOrders,

    CAST(
        SUM(CASE 
            WHEN po.ActualReceived <= po.ExpectedDate THEN 1 
            ELSE 0 
        END) * 100.0 / COUNT(po.POID)
    AS DECIMAL(5,2)) AS OnTimeDeliveryPct

FROM Purchase_Orders po
JOIN Suppliers s 
    ON po.SupplierID = s.SupplierID

WHERE po.POStatus = 'Received'

GROUP BY 
    s.SupplierID, 
    s.SupplierName

ORDER BY 
    OnTimeDeliveryPct DESC;


-- Analysis 2: Inventory Stockout Risk Classification

WITH InventoryStatus AS (
    SELECT 
        p.ProductID,
        p.ProductName,
        i.WarehouseID,
        i.QuantityOnHand,
        p.ReorderPoint,
        
        CASE 
            WHEN i.QuantityOnHand = 0 THEN 'Out of Stock'
            WHEN i.QuantityOnHand < p.ReorderPoint THEN 'Low Stock'
            ELSE 'Healthy'
        END AS StockStatus
    
    FROM Products p
    LEFT JOIN Inventory i 
        ON p.ProductID = i.ProductID
)

SELECT 
    StockStatus,
    COUNT(*) AS ProductCount
FROM InventoryStatus
GROUP BY StockStatus
ORDER BY ProductCount DESC;


-- Analysis 3: Order Fulfillment Time Distribution

USE SupplyChainDB;

WITH FulfillmentTime AS (
    SELECT 
        SalesOrderID,
        DATEDIFF(DAY, OrderDate, DeliveredDate) AS FulfillmentDays
    FROM Sales_Orders
    WHERE DeliveredDate IS NOT NULL
),
MedianCTE AS (
    SELECT 
        FulfillmentDays,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY FulfillmentDays) OVER () AS MedianValue
    FROM FulfillmentTime
)
SELECT 
    AVG(FulfillmentDays) AS AvgFulfillmentDays,
    MAX(MedianValue) AS MedianFulfillmentDays
FROM MedianCTE;

-- Analysis 4: Month-over-Month Revenue Trend



WITH MonthlyRevenue AS (
    SELECT 
        -- Use EOMONTH or DATEFROMPARTS for better performance than FORMAT
        DATEFROMPARTS(YEAR(OrderDate), MONTH(OrderDate), 1) AS MonthDate,
        SUM(QuantityOrdered * UnitPrice * (1 - DiscountPct/100.0)) AS Revenue
    FROM Sales_Orders
    WHERE OrderStatus = 'Delivered'
    GROUP BY YEAR(OrderDate), MONTH(OrderDate)
),
RevenueWithLag AS (
    SELECT 
        MonthDate,
        Revenue,
        LAG(Revenue) OVER (ORDER BY MonthDate) AS PreviousMonthRevenue
    FROM MonthlyRevenue
)
SELECT 
    FORMAT(MonthDate, 'yyyy-MM') AS Month, -- Format here for the final display only
    Revenue,
    PreviousMonthRevenue,
    CAST(
        (Revenue - PreviousMonthRevenue) * 100.0 / 
        NULLIF(PreviousMonthRevenue, 0) 
    AS DECIMAL(10, 2)) AS MoM_GrowthPct -- Increased precision to 10,2 for safety
FROM RevenueWithLag
ORDER BY MonthDate;

-- Analysis 5: Customer Segment Ranking

WITH CustomerRevenue AS (
    SELECT 
        c.CustomerID,
        c.CustomerSegment,
        SUM(so.QuantityOrdered * so.UnitPrice) AS TotalRevenue
    FROM Sales_Orders so
    JOIN Customers c 
        ON so.CustomerID = c.CustomerID
    WHERE so.OrderStatus = 'Delivered'
    GROUP BY c.CustomerID, c.CustomerSegment
)

SELECT 
    CustomerID,
    CustomerSegment,
    TotalRevenue,

    RANK() OVER (ORDER BY TotalRevenue DESC) AS RevenueRank,

    NTILE(4) OVER (ORDER BY TotalRevenue DESC) AS RevenueQuartile

FROM CustomerRevenue
ORDER BY RevenueRank;

-- Analysis 6: Warehouse Utilization Percentage

USE SupplyChainDB;

SELECT 
    w.WarehouseID,
    w.WarehouseName,

    SUM(i.QuantityOnHand) AS TotalStock,
    w.Capacity,

    CAST(
        SUM(i.QuantityOnHand) * 100.0 / NULLIF(w.Capacity,0)
    AS DECIMAL(5,2)) AS UtilizationPct

FROM Warehouses w
JOIN Inventory i 
    ON w.WarehouseID = i.WarehouseID

GROUP BY 
    w.WarehouseID, 
    w.WarehouseName, 
    w.Capacity

ORDER BY UtilizationPct DESC;

-- Analysis 7: Carrier On-Time Delivery Performance 

USE SupplyChainDB;

SELECT 
    CarrierName,

    COUNT(*) AS TotalShipments,

    SUM(CASE 
        WHEN ShipmentStatus = 'Delivered' THEN 1 
        ELSE 0 
    END) AS OnTimeDeliveries,

    CAST(
        SUM(CASE 
            WHEN ShipmentStatus = 'Delivered' THEN 1 
            ELSE 0 
        END) * 100.0 / COUNT(*)
    AS DECIMAL(5,2)) AS OnTimePct

FROM Shipments

GROUP BY CarrierName
ORDER BY OnTimePct DESC;

-- Analysis 8: Dead Stock & Inventory Turnover

USE SupplyChainDB;

WITH ProductSales AS (
    SELECT 
        ProductID,
        SUM(QuantityOrdered) AS TotalSold
    FROM Sales_Orders
    WHERE OrderStatus = 'Delivered'
    GROUP BY ProductID
),

InventoryData AS (
    SELECT 
        ProductID,
        SUM(QuantityOnHand) AS TotalStock
    FROM Inventory
    GROUP BY ProductID
)

SELECT 
    p.ProductID,
    p.ProductName,
    ISNULL(ps.TotalSold,0) AS TotalSold,
    id.TotalStock,

    CASE 
        WHEN ISNULL(ps.TotalSold,0) = 0 THEN 'Dead Stock'
        WHEN id.TotalStock > ps.TotalSold THEN 'Slow Moving'
        ELSE 'Fast Moving'
    END AS StockCategory

FROM Products p
LEFT JOIN ProductSales ps 
    ON p.ProductID = ps.ProductID
JOIN InventoryData id 
    ON p.ProductID = id.ProductID

ORDER BY StockCategory;

