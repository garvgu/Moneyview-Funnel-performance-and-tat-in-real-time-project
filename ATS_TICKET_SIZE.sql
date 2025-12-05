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
),

xhour_funnel AS (
  SELECT
    DATE(date_created) AS event_day,
    COUNT(DISTINCT id) AS starts_x,
    COUNT(DISTINCT IF(
      submission_date IS NOT NULL
      AND EXTRACT(HOUR FROM submission_date) <= {{hour}},
      id, NULL
    )) AS submits_x,
    COUNT(DISTINCT IF(
      disbursal_date IS NOT NULL
      AND EXTRACT(HOUR FROM disbursal_date) <= {{hour}},
      id, NULL
    )) AS disbursed_x,
    ROUND(AVG(IF(
      disbursal_date IS NOT NULL
      AND EXTRACT(HOUR FROM disbursal_date) <= {{hour}},
      loan_amount, NULL
    )),2) AS avg_ticket_size_x
  FROM base
  WHERE EXTRACT(HOUR FROM date_created) <= {{hour}}
  GROUP BY 1
)




SELECT
  df.event_day,

  -- Main funnel
  
  df.avg_ticket_size,

  -- X-hour funnel
  
  xf.avg_ticket_size_x

  
FROM daily_funnel df
LEFT JOIN xhour_funnel xf USING(event_day)

ORDER BY event_day DESC;
