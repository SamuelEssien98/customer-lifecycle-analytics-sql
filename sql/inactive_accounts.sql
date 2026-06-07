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
