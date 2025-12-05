WITH base AS (
  SELECT
    id,
    date_created,
    submission_date,
    disbursal_date,
    loan_amount
  FROM mv-dw-wi.lending.loan_application
  WHERE 1=1
    [[ AND DATE(disbursal_date) between date({{start_date}}) and date({{end_date}})  ]]
   
),



tat_raw AS (
  SELECT
    id,
    DATE(disbursal_date) AS disbursal_day,
    TIMESTAMP_DIFF(disbursal_date, date_created, SECOND) AS tat_seconds
  FROM base
  WHERE disbursal_date IS NOT NULL
),

tat_bucketed AS (
  SELECT
    disbursal_day,
    CASE
      WHEN tat_seconds < 300 THEN 'a. 0-5 min'
      WHEN tat_seconds < 600 THEN 'b. 5-10 min'
      WHEN tat_seconds < 900 THEN 'c. 10-15 min'
      WHEN tat_seconds < 1200 THEN 'd. 15-20 min'
      WHEN tat_seconds < 1500 THEN 'e. 20-25 min'
      ELSE 'f. 25+ min'
    END AS tat_bucket,
    COUNT(*) AS apps
  FROM tat_raw
  GROUP BY 1,2
)

SELECT *
   
FROM tat_bucketed
ORDER BY disbursal_day, tat_bucket;
