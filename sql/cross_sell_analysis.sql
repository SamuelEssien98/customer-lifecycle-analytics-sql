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
