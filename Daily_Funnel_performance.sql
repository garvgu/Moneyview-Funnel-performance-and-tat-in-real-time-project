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

daily_funnel AS (
  SELECT
    DATE(date_created) AS event_day,
    COUNT(DISTINCT id) AS starts,
    COUNT(DISTINCT submission_date) AS submits,
    COUNT(DISTINCT disbursal_date) AS disbursed,
    ROUND(AVG(loan_amount), 2) AS avg_ticket_size
  FROM base
  GROUP BY 1
)




SELECT
  df.event_day,

  -- Main funnel
  df.starts,
  df.submits,
  df.disbursed,
  df.avg_ticket_size,

  -- X-hour funnel
ROUND(df.submits / df.starts, 4) AS start_to_submit_rate,
  ROUND(df.disbursed / df.starts, 4) AS start_to_disbursal_rate,
  ROUND(df.disbursed / NULLIF(df.submits, 0), 4) AS submit_to_disbursal_rate 
FROM daily_funnel df

ORDER BY event_day DESC;
