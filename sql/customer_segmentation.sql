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
