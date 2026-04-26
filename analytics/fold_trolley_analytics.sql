-- ============================================================
-- FOLD TROLLEY TRACKER — SQL ANALYTICS QUERIES
-- Project: Supabase / PostgreSQL
-- Author: Arha
-- Description: Core analytics queries for trolley operations,
--              stock imbalance, user activity, and event trends.
-- ============================================================


-- ============================================================
-- 1. TROLLEY STOCK LEVEL PER LOCATION (vs. Targets)
--    Business question: Which locations are under/over stocked?
-- ============================================================
SELECT
    l.location_name,
    l.store_code,
    l.zone,
    l.target_min,
    l.target_max,
    COUNT(t.trolley_id)                          AS current_trolleys,
    CASE
        WHEN COUNT(t.trolley_id) < l.target_min  THEN 'UNDERSTOCKED ⚠️'
        WHEN COUNT(t.trolley_id) > l.target_max  THEN 'OVERSTOCKED ⚠️'
        ELSE                                          'OK ✅'
    END                                          AS stock_status
FROM public.locations l
LEFT JOIN public.trolleys t
    ON t.current_location_id = l.location_id
    AND t.status = 'active'
GROUP BY
    l.location_id,
    l.location_name,
    l.store_code,
    l.zone,
    l.target_min,
    l.target_max
ORDER BY l.store_code, l.zone;


-- ============================================================
-- 2. EVENT VOLUME BY LOCATION
--    Business question: Which locations see the most activity?
-- ============================================================
SELECT
    l.location_name,
    l.store_code,
    l.zone,
    COUNT(*)                                              AS total_events,
    COUNT(*) FILTER (WHERE te.action = 'pickup')          AS pickups,
    COUNT(*) FILTER (WHERE te.action = 'dropoff')         AS dropoffs,
    ROUND(
        100.0 * COUNT(*) FILTER (WHERE te.action = 'pickup')
        / NULLIF(COUNT(*), 0), 1
    )                                                     AS pickup_pct
FROM public.trolley_events te
JOIN public.locations l ON l.location_id = te.location_id
GROUP BY l.location_id, l.location_name, l.store_code, l.zone
ORDER BY total_events DESC;


-- ============================================================
-- 3. MOST ACTIVE TROLLEYS
--    Business question: Which trolleys are used most often?
-- ============================================================
SELECT
    te.trolley_id,
    t.status,
    COUNT(*)                                              AS total_events,
    COUNT(*) FILTER (WHERE te.action = 'pickup')          AS pickups,
    COUNT(*) FILTER (WHERE te.action = 'dropoff')         AS dropoffs,
    MIN(te.event_ts)                                      AS first_seen,
    MAX(te.event_ts)                                      AS last_seen
FROM public.trolley_events te
JOIN public.trolleys t ON t.trolley_id = te.trolley_id
GROUP BY te.trolley_id, t.status
ORDER BY total_events DESC;


-- ============================================================
-- 4. MOST ACTIVE USERS
--    Business question: Which users engage with trolleys most?
--    (Important for rewards targeting)
-- ============================================================
SELECT
    u.user_id,
    u.source,
    COUNT(te.event_id)                                    AS total_scans,
    COUNT(DISTINCT te.trolley_id)                         AS unique_trolleys,
    COUNT(DISTINCT te.location_id)                        AS locations_visited,
    COUNT(*) FILTER (WHERE te.action = 'pickup')          AS pickups,
    COUNT(*) FILTER (WHERE te.action = 'dropoff')         AS dropoffs,
    MIN(te.event_ts)                                      AS first_scan,
    MAX(te.event_ts)                                      AS last_scan
FROM public.users u
LEFT JOIN public.trolley_events te ON te.user_id = u.user_id
GROUP BY u.user_id, u.source
ORDER BY total_scans DESC;


-- ============================================================
-- 5. DAILY EVENT TREND
--    Business question: How is usage growing day over day?
-- ============================================================
SELECT
    DATE(te.event_ts AT TIME ZONE 'Australia/Melbourne') AS event_date,
    COUNT(*)                                              AS total_events,
    COUNT(*) FILTER (WHERE te.action = 'pickup')          AS pickups,
    COUNT(*) FILTER (WHERE te.action = 'dropoff')         AS dropoffs,
    COUNT(DISTINCT te.trolley_id)                         AS unique_trolleys,
    COUNT(DISTINCT te.user_id)                            AS unique_users
FROM public.trolley_events te
GROUP BY event_date
ORDER BY event_date;


-- ============================================================
-- 6. HOURLY ACTIVITY PATTERN (AEST)
--    Business question: When during the day are trolleys most used?
-- ============================================================
SELECT
    EXTRACT(HOUR FROM te.event_ts AT TIME ZONE 'Australia/Melbourne') AS hour_of_day,
    COUNT(*)                                              AS total_events,
    COUNT(*) FILTER (WHERE te.action = 'pickup')          AS pickups,
    COUNT(*) FILTER (WHERE te.action = 'dropoff')         AS dropoffs
FROM public.trolley_events te
GROUP BY hour_of_day
ORDER BY hour_of_day;


-- ============================================================
-- 7. TROLLEYS WITH NO RECENT ACTIVITY (Inactive / Lost)
--    Business question: Which trolleys haven't been scanned?
--    Useful for identifying lost or misplaced trolleys.
-- ============================================================
SELECT
    t.trolley_id,
    t.status,
    t.last_event_ts,
    t.last_action,
    l.location_name                                       AS current_location,
    CASE
        WHEN t.last_event_ts IS NULL                      THEN 'Never scanned'
        WHEN t.last_event_ts < NOW() - INTERVAL '7 days' THEN 'Inactive > 7 days'
        ELSE                                                   'Recently active'
    END                                                   AS activity_status
FROM public.trolleys t
LEFT JOIN public.locations l ON l.location_id = t.current_location_id
ORDER BY t.last_event_ts ASC NULLS FIRST
LIMIT 20;


-- ============================================================
-- 8. STORE-LEVEL SUMMARY
--    Business question: How is each retailer performing overall?
-- ============================================================
SELECT
    l.store_code,
    SPLIT_PART(l.location_name, ' - ', 1)                AS retailer,
    COUNT(DISTINCT te.event_id)                           AS total_events,
    COUNT(DISTINCT te.trolley_id)                         AS active_trolleys,
    COUNT(DISTINCT te.user_id)                            AS unique_users,
    COUNT(*) FILTER (WHERE te.action = 'pickup')          AS pickups,
    COUNT(*) FILTER (WHERE te.action = 'dropoff')         AS dropoffs
FROM public.locations l
LEFT JOIN public.trolley_events te ON te.location_id = l.location_id
GROUP BY l.store_code, retailer
ORDER BY total_events DESC;


-- ============================================================
-- 9. PICKUP-TO-DROPOFF RATIO BY ZONE
--    Business question: Are certain zones net consumers or
--    net returnees of trolleys?
-- ============================================================
SELECT
    l.zone,
    COUNT(*) FILTER (WHERE te.action = 'pickup')          AS pickups,
    COUNT(*) FILTER (WHERE te.action = 'dropoff')         AS dropoffs,
    ROUND(
        1.0 * COUNT(*) FILTER (WHERE te.action = 'pickup')
        / NULLIF(COUNT(*) FILTER (WHERE te.action = 'dropoff'), 0), 2
    )                                                     AS pickup_to_dropoff_ratio
FROM public.trolley_events te
JOIN public.locations l ON l.location_id = te.location_id
GROUP BY l.zone
ORDER BY pickup_to_dropoff_ratio DESC NULLS LAST;


-- ============================================================
-- 10. REWARD ELIGIBILITY — Users who dropped off trolleys
--     Business question: Who should earn reward points?
--     (Ready to populate reward_ledger)
-- ============================================================
SELECT
    te.user_id,
    te.trolley_id,
    te.location_id,
    l.location_name,
    te.event_ts,
    10                                                    AS points_to_award,
    'trolley_dropoff'                                     AS reason
FROM public.trolley_events te
JOIN public.locations l ON l.location_id = te.location_id
WHERE te.action = 'dropoff'
  AND NOT EXISTS (
      SELECT 1 FROM public.reward_ledger rl
      WHERE rl.source_event_id = te.event_id
  )
ORDER BY te.event_ts;
