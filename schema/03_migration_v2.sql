-- ============================================================
-- FOLD TROLLEY TRACKER — Migration v2
-- Run this against an existing v1 database to upgrade
-- ============================================================

-- 1. Add new columns to trolley_events
ALTER TABLE public.trolley_events
  ADD COLUMN IF NOT EXISTS condition VARCHAR DEFAULT 'good'
    CHECK (condition IN ('good', 'damaged', 'needs_cleaning')),
  ADD COLUMN IF NOT EXISTS source VARCHAR DEFAULT 'app_user'
    CHECK (source IN ('app_user', 'staff_manual', 'bulk_restock')),
  ADD COLUMN IF NOT EXISTS dwell_minutes NUMERIC;

-- 2. Add restock_events table
CREATE TABLE IF NOT EXISTS public.restock_events (
    restock_id    BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    location_id   BIGINT NOT NULL REFERENCES public.locations(location_id),
    trolley_count INTEGER NOT NULL CHECK (trolley_count > 0),
    staff_id      VARCHAR NOT NULL,
    notes         TEXT,
    event_ts      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.restock_events ENABLE ROW LEVEL SECURITY;
CREATE POLICY service_full_restock ON public.restock_events FOR ALL TO service_role USING (true) WITH CHECK (true);
CREATE POLICY read_restock ON public.restock_events FOR SELECT USING (true);

-- 3. GPS coordinates for all 7 locations
UPDATE public.locations SET latitude = -37.8140, longitude = 144.9584 WHERE location_name = 'Coles - Entrance';
UPDATE public.locations SET latitude = -37.8143, longitude = 144.9581 WHERE location_name = 'Coles - Basement';
UPDATE public.locations SET latitude = -37.8138, longitude = 144.9633 WHERE location_name = 'Woolies - Parking';
UPDATE public.locations SET latitude = -37.8141, longitude = 144.9630 WHERE location_name = 'Woolies - Basement';
UPDATE public.locations SET latitude = -37.8128, longitude = 144.9650 WHERE location_name = 'Aldi - Entrance';
UPDATE public.locations SET latitude = -37.8131, longitude = 144.9653 WHERE location_name = 'Aldi - Parking';
UPDATE public.locations SET latitude = -37.8134, longitude = 144.9648 WHERE location_name = 'Aldi - Basement';

-- 4. Auto-reward trigger — fires on every dropoff insert
CREATE OR REPLACE FUNCTION public.auto_award_reward()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.action = 'dropoff' THEN
    INSERT INTO public.reward_ledger (user_id, trolley_id, points, reason, source_event_id)
    VALUES (NEW.user_id, NEW.trolley_id, 10, 'trolley_dropoff', NEW.event_id);
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_auto_reward ON public.trolley_events;
CREATE TRIGGER trg_auto_reward
  AFTER INSERT ON public.trolley_events
  FOR EACH ROW EXECUTE FUNCTION public.auto_award_reward();

-- 5. Dwell time view — matches each dropoff to its preceding pickup
CREATE OR REPLACE VIEW public.trolley_dwell_times AS
SELECT
    d.event_id                                                          AS dropoff_event_id,
    d.trolley_id,
    d.user_id,
    d.location_id,
    p.event_ts                                                          AS pickup_ts,
    d.event_ts                                                          AS dropoff_ts,
    ROUND(EXTRACT(EPOCH FROM (d.event_ts - p.event_ts)) / 60, 1)       AS dwell_minutes,
    p.location_id                                                       AS pickup_location_id
FROM public.trolley_events d
JOIN LATERAL (
    SELECT event_ts, location_id FROM public.trolley_events p2
    WHERE p2.trolley_id = d.trolley_id
      AND p2.action = 'pickup'
      AND p2.event_ts < d.event_ts
    ORDER BY p2.event_ts DESC
    LIMIT 1
) p ON true
WHERE d.action = 'dropoff';

-- 6. Backfill reward_ledger for any existing dropoffs not yet awarded
INSERT INTO public.reward_ledger (user_id, trolley_id, points, reason, source_event_id)
SELECT te.user_id, te.trolley_id, 10, 'trolley_dropoff', te.event_id
FROM public.trolley_events te
WHERE te.action = 'dropoff'
  AND NOT EXISTS (
    SELECT 1 FROM public.reward_ledger rl WHERE rl.source_event_id = te.event_id
  );
