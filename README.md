Olist Delivery Performance Analysis

Overview
Analyzed end-to-end delivery performance across Olist’s e-commerce logistics system to identify what drives delays and how they impact customer satisfaction.

Key Findings (30-second read)

* 92% of orders are on time or early — but misleading
  Deliveries happen about 11 days earlier than estimated due to overly conservative delivery promises

* Shipping is the main bottleneck
  Late orders have 3× longer shipping time
  Approval and dispatch stages remain stable

* Delays strongly impact customer satisfaction
  Early: ~4.3 rating
  Late: ~2.5 rating (about 40% drop)

* System breaks under peak demand
  Late delivery rate exceeds 20% during high-volume months

* Capacity limit identified (~6,500–7,000 orders/month)
  Performance declines beyond this threshold

Business Impact

Rising demand leads to shipping pressure, which causes delivery delays and results in lower customer satisfaction

Recommendations

* Fix shipping bottleneck
  Evaluate carrier performance and optimize high-delay routes

* Prepare for peak demand
  Forecast volume and scale logistics capacity ahead of spikes

* Improve delivery estimates
  Reduce excessive buffer to reflect realistic timelines

* Prioritize delay reduction
  Small improvements lead to large gains in customer satisfaction

Tools
SQL (MySQL), Excel, Power Query, Power BI (in progress)

Sample SQL Logic

CASE
WHEN delivery_delay < 0 THEN 'Early'
WHEN delivery_delay = 0 THEN 'On Time'
ELSE 'Late'
END AS delivery_status

Dataset
Brazilian E-commerce Public Dataset (ta Analyst | Supply Chain and Operations Analytics


