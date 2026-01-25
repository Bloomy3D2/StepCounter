-- Analytics reports (examples)
-- Run with service role / in SQL editor as project owner (RLS bypass),
-- otherwise users will only see their own events.

-- 1) DAU
-- Daily active users = distinct users with "session_start" (or "app_open") per day
SELECT
  date_trunc('day', created_at) AS day,
  COUNT(DISTINCT user_id)       AS dau
FROM public.analytics_events
WHERE event_name IN ('session_start', 'app_open')
GROUP BY 1
ORDER BY 1 DESC
LIMIT 60;

-- 2) MAU (last 30 days)
SELECT COUNT(DISTINCT user_id) AS mau_30d
FROM public.analytics_events
WHERE event_name IN ('session_start', 'app_open')
  AND created_at >= NOW() - INTERVAL '30 days';

-- 3) Retention D1/D7/D30 (cohort by signup day)
-- Requires "sign_up_success" and "session_start" events.
WITH cohorts AS (
  SELECT
    user_id,
    date_trunc('day', MIN(created_at))::date AS signup_day
  FROM public.analytics_events
  WHERE event_name = 'sign_up_success'
  GROUP BY 1
),
activity AS (
  SELECT DISTINCT
    user_id,
    date_trunc('day', created_at)::date AS active_day
  FROM public.analytics_events
  WHERE event_name IN ('session_start', 'app_open')
),
joined AS (
  SELECT
    c.signup_day,
    a.user_id,
    (a.active_day - c.signup_day) AS day_offset
  FROM cohorts c
  JOIN activity a USING (user_id)
)
SELECT
  signup_day,
  COUNT(DISTINCT CASE WHEN day_offset = 1  THEN user_id END) AS d1_users,
  COUNT(DISTINCT CASE WHEN day_offset = 7  THEN user_id END) AS d7_users,
  COUNT(DISTINCT CASE WHEN day_offset = 30 THEN user_id END) AS d30_users,
  COUNT(DISTINCT user_id) FILTER (WHERE day_offset = 0)      AS cohort_size
FROM joined
GROUP BY 1
ORDER BY 1 DESC
LIMIT 60;

-- 4) Funnel: view list -> view detail -> join attempt -> join success
WITH e AS (
  SELECT
    user_id,
    session_id,
    created_at,
    event_name,
    COALESCE(challenge_id::text, props->>'challenge_id') AS cid
  FROM public.analytics_events
  WHERE event_name IN (
    'view_challenges_list',
    'view_challenge_detail',
    'join_attempt',
    'join_success'
  )
),
steps AS (
  SELECT
    user_id,
    session_id,
    cid,
    MIN(created_at) FILTER (WHERE event_name = 'view_challenges_list')  AS s1_list,
    MIN(created_at) FILTER (WHERE event_name = 'view_challenge_detail') AS s2_detail,
    MIN(created_at) FILTER (WHERE event_name = 'join_attempt')          AS s3_attempt,
    MIN(created_at) FILTER (WHERE event_name = 'join_success')          AS s4_success
  FROM e
  GROUP BY 1,2,3
)
SELECT
  COUNT(*) FILTER (WHERE s1_list   IS NOT NULL) AS step1_list,
  COUNT(*) FILTER (WHERE s2_detail IS NOT NULL) AS step2_detail,
  COUNT(*) FILTER (WHERE s3_attempt IS NOT NULL) AS step3_attempt,
  COUNT(*) FILTER (WHERE s4_success IS NOT NULL) AS step4_success
FROM steps;

-- 5) Payment conversion (deposit success)
SELECT
  date_trunc('day', created_at) AS day,
  COUNT(*) FILTER (WHERE event_name = 'deposit_payment_created') AS deposit_created,
  COUNT(*) FILTER (WHERE event_name = 'deposit_success')         AS deposit_success,
  SUM(amount) FILTER (WHERE event_name = 'deposit_success')      AS deposit_sum
FROM public.analytics_events
WHERE event_name IN ('deposit_payment_created', 'deposit_success')
GROUP BY 1
ORDER BY 1 DESC
LIMIT 60;
