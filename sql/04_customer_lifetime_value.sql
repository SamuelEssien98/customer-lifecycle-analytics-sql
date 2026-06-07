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
