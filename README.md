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

![ERD](images/erd.png)

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

**SQL Techniques Used**

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
