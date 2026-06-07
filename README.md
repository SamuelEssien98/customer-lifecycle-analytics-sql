# Customer Lifecycle Analytics Using SQL

## Project Overview

A digital financial services company wanted to better understand customer engagement, retention, and profitability across its savings and investment products.

Using SQL, I analyzed customer, transaction, savings, and investment data to answer four key business questions:

1. Which customers actively use multiple financial products?
2. How frequently do customers transact?
3. Which accounts show signs of inactivity?
4. Which customers generate the highest long-term value?

The analysis demonstrates how SQL can be used to transform transactional data into actionable business insights that support growth, retention, and customer value optimization.

## Dataset Overview

The dataset represents customer activity on a digital financial services platform and contains information on customer profiles, savings transactions, investment plans, and withdrawals.

## Database Schema (ERD)

The diagram below illustrates the relationship between customers, savings accounts, investment plans, and withdrawal records.

https://github.com/SamuelEssien98/customer-lifecycle-analytics-sql/blob/58ca02602b3d35e333679427cb31467028e69eb7/images/ERD.png

### Tables Used

| Table | Description |
|---------|-------------|
| users_customuser | Customer demographic and account information |
| savings_savingsaccount | Savings deposit transactions |
| plans_plan | Savings and investment plan records |
| withdrawals_withdrawal | Withdrawal transactions |

### Key Fields

- owner_id – Unique customer identifier
- plan_id – Unique plan identifier
- transaction_date – Date of transaction
- confirmed_amount – Value of successful deposits
- amount_withdrawn – Value of withdrawals
- is_regular_savings – Indicates savings plans
- is_a_fund – Indicates investment plans

### Analysis Scope

The project focuses on four business areas:

- Product Adoption (Cross-Sell Analysis)
- Customer Engagement (Transaction Frequency)
- Customer Retention (Inactivity Monitoring)
- Customer Value (Customer Lifetime Value)
  
## Key Business Questions

1. Which customers actively use both savings and investment products?
2. How frequently do customers transact and how can they be segmented by activity level?
3. Which accounts show signs of inactivity and potential churn?
4. Which customers generate the highest long-term value?

## Analysis 1: Cross-Sell Opportunities

**Business Problem**

Financial institutions often generate higher customer lifetime value when customers adopt multiple products. The business wanted to identify customers who actively use both savings and investment products in order to uncover cross-selling opportunities and prioritize high-value customer segments.

**Business Question**

Which customers have at least one funded savings plan and one funded investment plan, and how much have they deposited across these products?

**Approach**

To answer this question, I identified customers with funded savings plans and customers with funded investment plans using separate SQL Common Table Expressions (CTEs). The two groups were then combined to identify customers who held both product types. Finally, total deposits were calculated and customers were ranked based on their deposit value.

**Analytical Methods**

- Common Table Expressions (CTEs)
- INNER JOINs
- Aggregations (COUNT, SUM)
- Filtering
- Sorting and Ranking

**SQL Query**
-- Q1: High-Value Customers with Multiple Products
-- Identifies customers holding both a funded savings plan and a funded investment plan
-- Ordered by total deposits descending to surface highest-value cross-sell opportunities
WITH savings_customers AS (
    SELECT
        p.owner_id,
        COUNT(DISTINCT p.id)     AS savings_count,
        SUM(s.confirmed_amount)  AS savings_deposit   -- confirmed_amount is the inflow field (in kobo)
    FROM plans_plan p
    JOIN savings_savingsaccount s
        ON p.id = s.plan_id
    WHERE s.transaction_status LIKE "%success%"   -- handles status variants e.g. "monnify_success"
      AND p.is_regular_savings = 1
    GROUP BY p.owner_id
),
investment_customers AS (
    SELECT
        p.owner_id,
        COUNT(DISTINCT p.id)  AS investment_count,
        SUM(p.amount)         AS investment_deposit   -- plans_plan.amount reflects committed fund value
    FROM plans_plan p
    JOIN savings_savingsaccount s
        ON p.id = s.plan_id
    WHERE p.amount > 0
      AND p.is_a_fund = 1
    GROUP BY p.owner_id
)
SELECT
    sc.owner_id                                    AS owner_id,
    CONCAT(uc.first_name, ' ', uc.last_name)       AS name,
    sc.savings_count                               AS savings_count,
    ic.investment_count                            AS investment_count,
    (sc.savings_deposit + ic.investment_deposit)   AS total_deposits
FROM savings_customers sc
JOIN investment_customers ic
    ON sc.owner_id = ic.owner_id
JOIN users_customuser uc
    ON sc.owner_id = uc.id
ORDER BY total_deposits DESC;

**Business Value**

Customers who actively use both savings and investment products are typically more engaged and valuable to the business. Identifying this segment helps marketing and relationship management teams focus retention efforts, increase product adoption, and improve customer lifetime value.

**Potential Recommendations**

- Develop targeted campaigns for customers with savings products but no investment products.
- Create personalized product recommendations based on customer transaction behavior.
- Prioritize multi-product customers for loyalty and retention initiatives.
- Monitor deposit trends to identify customers likely to adopt additional financial products.

## Analysis 2: Customer Engagement Segmentation

**Business Problem**

Customer activity levels vary significantly across the platform. Without segmentation, it becomes difficult to identify highly engaged customers, understand usage patterns, or design targeted engagement strategies.

**Business Question**

How frequently do customers transact on the platform, and how can they be grouped into meaningful engagement segments?

**Approach**

I calculated the number of transactions performed by each customer on a monthly basis and then derived each customer's average monthly transaction volume. Customers were subsequently categorized into High Frequency, Medium Frequency, and Low Frequency segments based on their average transaction activity.

**Analytical Methods**

- Common Table Expressions (CTEs)
- Date Functions
- CASE Statements
- Aggregations
- GROUP BY
- Customer Segmentation Logic

**SQL Query**

-- Q2: Transaction Frequency Segmentation
-- Segments customers by average monthly transaction frequency
-- Uses DATE_FORMAT('%Y-%m') to group by year-month, preventing cross-year month collapsing

WITH monthly_transactions AS (
    SELECT
        s.owner_id,
        DATE_FORMAT(s.transaction_date, '%Y-%m') AS 'year_month',
        COUNT(s.id)                               AS transaction_count

    FROM savings_savingsaccount s
    WHERE s.transaction_status LIKE "%success%"
    GROUP BY s.owner_id, DATE_FORMAT(s.transaction_date, '%Y-%m')
),

user_avg_transactions AS (
    SELECT
        mt.owner_id,
        AVG(mt.transaction_count) AS avg_monthly_transactions

    FROM monthly_transactions mt
    GROUP BY mt.owner_id
)

SELECT
    CASE
        WHEN uat.avg_monthly_transactions >= 10 THEN "High Frequency"
        WHEN uat.avg_monthly_transactions >= 3  THEN "Medium Frequency"
        ELSE "Low Frequency"
    END                              AS frequency_category,

    COUNT(DISTINCT uc.id)            AS customer_count,
    AVG(uat.avg_monthly_transactions) AS avg_transactions_per_month

FROM users_customuser uc
LEFT JOIN user_avg_transactions uat
    ON uc.id = uat.owner_id

GROUP BY
    CASE
        WHEN uat.avg_monthly_transactions >= 10 THEN "High Frequency"
        WHEN uat.avg_monthly_transactions >= 3  THEN "Medium Frequency"
        ELSE "Low Frequency"
    END

ORDER BY avg_transactions_per_month DESC;

**Visualization**

Figure 1: Customer Transaction Frequency Segmentation

Customers were segmented into High Frequency, Medium Frequency, and Low Frequency groups based on their average monthly transaction activity.

https://github.com/SamuelEssien98/customer-lifecycle-analytics-sql/blob/4cf8046649994d5a388b0b4446d39a6917305caa/images/Figure%201.png

**Key Insight**

The analysis revealed that **85.27% of customers fall within the Low Frequency segment**, while only **5.89%** and **8.84%** belong to the High Frequency and Medium Frequency segments respectively. This indicates that the majority of customers interact with the platform infrequently, suggesting significant opportunities to improve engagement and increase transaction activity.

**Why This Analysis Matters**

Understanding customer engagement patterns enables businesses to tailor marketing campaigns, improve retention efforts, and allocate resources more effectively across different customer segments.

**Potential Recommendations**

- Introduce loyalty programs for high-frequency customers to strengthen retention.
- Design targeted engagement campaigns for medium-frequency customers to increase activity.
- Implement reactivation campaigns for low-frequency customers who may be at risk of churn.
- Monitor changes in customer segments over time to identify shifts in engagement behavior.
