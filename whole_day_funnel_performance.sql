WITH base AS (
  SELECT
    id,
    date_created,
    submission_date,
    disbursal_date,
    loan_amount
  FROM mv-dw-wi.lending.loan_application
  WHERE 1=1
    [[ AND DATE(date_created) between date({{start_date}}) and date({{end_date}})  ]]
    
),


 
hour24_funnel AS (
  SELECT
    DATE(date_created) AS event_day,
    COUNT(DISTINCT id) AS starts_24,
    COUNT(DISTINCT IF(
      submission_date IS NOT NULL
      AND TIMESTAMP_DIFF(submission_date, date_created, HOUR) < 24,
      id, NULL
    )) AS submits_24,
    COUNT(DISTINCT disbursal_date) AS disbursed_24
  FROM base
  GROUP BY 1
)



SELECT
  f24.event_day,
ROUND(f24.submits_24 / f24.starts_24, 4) AS start_to_submit_rate,
  ROUND(f24.disbursed_24 / f24.starts_24, 4) AS start_to_disbursal_rate,
  ROUND(f24.disbursed_24 / NULLIF(f24.submits_24, 0), 4) AS submit_to_disbursal_rate 
  

  -- 24-hour funnel

FROM  hour24_funnel f24 
 
ORDER BY event_day DESC;
