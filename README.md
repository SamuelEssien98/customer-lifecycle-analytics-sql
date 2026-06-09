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

**Visualization**

Figure 1: Deposit Contribution by Cross-Sell Customer Tier

Customers who actively used both savings and investment products were segmented into four tiers based on their total deposit value. The chart compares each segment's share of customers against its share of total deposits.

https://github.com/SamuelEssien98/customer-lifecycle-analytics-sql/blob/b515d434a899f449242befd8330b206f128ea266/images/Figure%20A.png

**Key Insight**

The analysis revealed a significant concentration of deposits among a small segment of customers. While **Strategic Customers represented only 18.6% of cross-sell customers, they contributed approximately 90.0% of total deposits**. Conversely, **Emerging Customers accounted for 56.4% of customers but generated less than 1% of total deposits**.

**Business Value**

The deposit base is highly concentrated among a relatively small group of multi-product customers. This suggests that not all customers contribute equally to business value and that customer management strategies should be tailored based on deposit behavior and overall contribution. The findings also indicate a strong opportunity to develop customers within the Growth and High Value segments, as these groups collectively represent 25% of customers but contribute less than 10% of total deposits.

**Potential Recommendations**

- Prioritize Strategic Customers for retention, relationship management, and premium product offerings.
- Develop targeted engagement programs aimed at moving Growth Customers into the Strategic segment.
- Analyze the product adoption and transaction behaviors of Strategic Customers to identify characteristics that can be replicated across other customer groups.
- Monitor customer movement between tiers as a key performance indicator for customer growth and value creation.
- Reduce concentration risk by increasing the value contribution of Growth and High Value customer segments over time.

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

Figure 2: Customer Transaction Frequency Segmentation

Customers were segmented into High Frequency, Medium Frequency, and Low Frequency groups based on their average monthly transaction activity.

https://github.com/SamuelEssien98/customer-lifecycle-analytics-sql/blob/9ea2e8aaf978b69caa0bddfc6e90fa3d0cc8a1a3/images/Figure%20B.png

**Key Insight**

The analysis revealed that **85.27% of customers fall within the Low Frequency segment**, while only **5.89%** and **8.84%** belong to the High Frequency and Medium Frequency segments respectively. This indicates that the majority of customers interact with the platform infrequently, suggesting significant opportunities to improve engagement and increase transaction activity.

**Why This Analysis Matters**

Understanding customer engagement patterns enables businesses to tailor marketing campaigns, improve retention efforts, and allocate resources more effectively across different customer segments.

**Potential Recommendations**

- Introduce loyalty programs for high-frequency customers to strengthen retention.
- Design targeted engagement campaigns for medium-frequency customers to increase activity.
- Implement reactivation campaigns for low-frequency customers who may be at risk of churn.
- Monitor changes in customer segments over time to identify shifts in engagement behavior.

## Analysis 3: Customer Inactivity Monitoring

**Business Problem**

Customer inactivity is often an early indicator of churn. Without a process for monitoring dormant accounts, the business risks losing customers before intervention measures can be taken.

**Business Question**

Which active customer accounts have not recorded any inflow transactions in the last 365 days?

**Approach**

I analyzed savings and investment account activity to determine the most recent transaction date associated with each account. Accounts with no inflow activity within the last 365 days were flagged as inactive and ranked based on the number of inactivity days.

**Analytical Methods**

- Common Table Expressions (CTEs)
- Date-Based Analysis
- Transaction Monitoring
- Account Activity Assessment
- Churn Risk Identification

**SQL Query**

-- Q3: Account Inactivity Alert
-- Flags savings and investment accounts with no successful inflow transaction in the last 365 days
-- Last transaction date is sourced from both plans_plan and savings_savingsaccount via COALESCE
-- LEFT JOIN between CTEs ensures accounts present in only one table are not silently dropped

WITH plans_max_transactions AS (
    SELECT
        p.id,
        p.owner_id,
        p.is_a_fund,
        p.is_regular_savings,
        MAX(p.last_charge_date) AS last_transaction_date

    FROM plans_plan p
    JOIN savings_savingsaccount s
        ON p.id = s.plan_id
    WHERE (p.is_a_fund = 1 OR p.is_regular_savings = 1)
      AND s.transaction_status LIKE "%success%"
    GROUP BY p.id, p.owner_id, p.is_a_fund, p.is_regular_savings
),

savings_max_transactions AS (
    SELECT
        s.plan_id,
        s.owner_id,
        MAX(DATE(s.transaction_date)) AS savings_last_transaction_date

    FROM savings_savingsaccount s
    WHERE s.transaction_status LIKE "%success%"
    GROUP BY s.plan_id, s.owner_id
)

SELECT
    pmt.id                                                                      AS plan_id,
    pmt.owner_id                                                                AS owner_id,
    CASE
        WHEN pmt.is_regular_savings = 1 THEN "Savings"
        WHEN pmt.is_a_fund = 1          THEN "Investment"
    END                                                                         AS type,
    COALESCE(pmt.last_transaction_date, smt.savings_last_transaction_date)      AS last_transaction_date,
    DATEDIFF(
        CURRENT_DATE,
        COALESCE(pmt.last_transaction_date, smt.savings_last_transaction_date)
    )                                                                           AS inactivity_days

FROM plans_max_transactions pmt
LEFT JOIN savings_max_transactions smt   -- LEFT JOIN preserves plans that appear in only one source
    ON pmt.id = smt.plan_id

WHERE DATEDIFF(
    CURRENT_DATE,
    COALESCE(pmt.last_transaction_date, smt.savings_last_transaction_date)
) > 365

ORDER BY inactivity_days DESC;

**Visualization**

Figure 3: Customer Churn Risk by Product Type

Dormant customers were segmented by inactivity duration and product type to identify where customer disengagement is most prevalent.

https://github.com/SamuelEssien98/customer-lifecycle-analytics-sql/blob/9ea2e8aaf978b69caa0bddfc6e90fa3d0cc8a1a3/images/Figure%20C.png

**Key Insight**

Savings products account for the majority of dormant customers across all inactivity bands. The highest concentration of inactive customers occurs within the 1–2 year band, with 339 dormant savings customers and 199 dormant investment customers. This suggests that customer disengagement is concentrated among relatively recent users and presents an opportunity for proactive re-engagement initiatives.

**Business Value**

The analysis indicates that inactivity is more pronounced among savings customers than investment customers. Since most dormant customers fall within the 1–2 year inactivity range, the business has a significant opportunity to recover customers before they become permanently disengaged.

**Potential Recommendations**

- Prioritize reactivation campaigns targeting dormant savings customers, where inactivity is most prevalent.
- Implement automated alerts when customers approach one year of inactivity.
- Investigate differences in engagement between savings and investment customers to identify behaviors associated with stronger retention.
- Establish inactivity monitoring dashboards to track churn risk and reactivation performance over time.

## Analysis 4: Customer Lifetime Value Estimation

**Business Problem**

Customer acquisition and retention resources are limited. The business needed a way to estimate which customers generate the highest long-term value in order to prioritize retention efforts and maximize return on customer engagement investments.

**Business Question**

Which customers generate the highest estimated lifetime value based on account tenure and transaction activity?

**Approach**

I combined customer tenure information with transaction history to estimate Customer Lifetime Value (CLV). Account tenure was calculated based on the number of months since customer signup, while transaction volume and estimated profit per transaction were used to project annual customer value.

**Analytical Methods**

- Customer Lifetime Value (CLV) Modeling
- Date-Based Analysis
- Customer Profitability Analysis
- Transaction Aggregation
- Business Metric Development

**SQL Query**

-- Q4: Customer Lifetime Value (CLV) Estimation
-- Estimates CLV per active customer using tenure and transaction behaviour
-- Formula: CLV = (total_transactions / tenure_months) * 12 * avg_profit_per_transaction
-- Profit per transaction = 0.1% of confirmed_amount (converted from kobo to naira via * 0.001)

WITH transactions AS (
    SELECT
        s.owner_id,
        COUNT(s.id)                          AS total_transactions,
        AVG(s.confirmed_amount * 0.001)      AS avg_profit_per_transaction   -- 0.1% of value in naira

    FROM savings_savingsaccount s
    WHERE s.transaction_status LIKE "%success%"   -- handles status field variants
    GROUP BY s.owner_id
),

account_tenure AS (
    SELECT
        uc.id,
        CONCAT(uc.first_name, ' ', uc.last_name)          AS name,
        DATEDIFF(CURRENT_DATE, DATE(uc.date_joined)) / 30  AS tenure_months   -- DATE() handles mixed datetime formats

    FROM users_customuser uc
    WHERE uc.is_active = 1   -- exclude churned or suspended accounts
)

SELECT
    a.id                AS customer_id,
    a.name,
    a.tenure_months,
    t.total_transactions,
    CASE
        WHEN a.tenure_months > 0
            THEN ROUND((t.total_transactions / a.tenure_months) * 12 * t.avg_profit_per_transaction, 2)
        ELSE 0           -- guard against division by zero for very recently signed-up customers
    END                 AS estimated_clv

FROM account_tenure a
JOIN transactions t
    ON a.id = t.owner_id

ORDER BY estimated_clv DESC;

**Visualization**

Figure 4: Customer Lifetime Value Distribution by Segment

Customers were grouped into lifetime value segments based on estimated CLV to understand the distribution of customer value across the platform.

https://github.com/SamuelEssien98/customer-lifecycle-analytics-sql/blob/9ea2e8aaf978b69caa0bddfc6e90fa3d0cc8a1a3/images/Figure%20D.png

**Key Insight**

Customer value is highly concentrated among a small subset of customers. Although Top Value customers represent only 6.69% of the customer base, they contribute approximately 78% of total estimated customer lifetime value. In contrast, Low Value customers account for 78.18% of customers but contribute less than 5% of total estimated value.

**Business Value**

The analysis reveals a classic Pareto-like distribution, where a small proportion of customers generates the majority of long-term value. This suggests that customer retention and relationship management efforts should not be distributed evenly across the customer base. Instead, resources should be prioritized toward customers with the highest projected lifetime value.

**Potential Recommendations**

- Develop premium retention programs for Top Value customers.
- Assign dedicated relationship management resources to high-value customer segments.
- Analyze behavioral patterns of Top Value customers to improve acquisition targeting.
- Implement migration strategies to move customers from Low and Medium Value segments into higher-value tiers.
- Track changes in customer value segments over time as a strategic KPI.

## Key Takeaways

- Customer value is highly concentrated, with Top Value customers contributing 78% of estimated lifetime value despite representing only 6.7% of the customer base.
- Strategic cross-sell customers account for 90% of total deposits, highlighting the importance of multi-product adoption.
- More than 85% of customers were classified as low-frequency users, indicating substantial opportunities to improve engagement.
- Dormant accounts were concentrated within the 1–2 year inactivity range, suggesting that proactive re-engagement initiatives could recover a significant number of customers before permanent churn occurs.

**Link to Notion**
https://goldenrod-euphonium-cd8.notion.site/Customer-Lifecycle-Analytics-Using-SQL-37861727cfc380f6b356d1dfe72ad425?source=copy_link
