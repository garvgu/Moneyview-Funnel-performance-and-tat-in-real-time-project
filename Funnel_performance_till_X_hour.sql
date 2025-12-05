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
  xf.event_day,

  -- Main funnel
  
  -- X-hour funnel
  xf.starts_x,
  xf.submits_x,
  xf.disbursed_x,
  xf.avg_ticket_size_x,
  ROUND(xf.submits_x / xf.starts_x, 4) AS start_to_submit_rate_x,
  ROUND(xf.disbursed_x / xf.starts_x, 4) AS start_disbursal_rate_x,
  ROUND(xf.disbursed_x / NULLIF(xf.submits_x, 0), 4) AS submit_to_disbursal_rate_x
  -- 24-hour funnel
 
FROM xhour_funnel xf 


ORDER BY event_day DESC;
