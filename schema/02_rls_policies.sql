-- ============================================================
-- FOLD TROLLEY TRACKER — Row Level Security Policies
-- Apply after running 01_create_tables.sql
-- ============================================================

-- Enable RLS on all tables
ALTER TABLE public.trolleys        ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.users           ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.locations       ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.trolley_events  ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reward_ledger   ENABLE ROW LEVEL SECURITY;

-- -------------------------------------------------------
-- TROLLEY_EVENTS policies
-- -------------------------------------------------------

-- Anonymous users: read all events
CREATE POLICY demo_anon_read_events ON public.trolley_events
    FOR SELECT TO anon USING (true);

-- Anonymous users: insert only if trolley + location are valid
CREATE POLICY demo_anon_insert_events ON public.trolley_events
    FOR INSERT TO anon
    WITH CHECK (
        EXISTS (SELECT 1 FROM public.trolleys t WHERE t.trolley_id = trolley_events.trolley_id)
        AND EXISTS (SELECT 1 FROM public.locations l WHERE l.location_id = trolley_events.location_id AND l.is_active = true)
        AND action IN ('pickup', 'dropoff')
    );

-- Authenticated users: read all events
CREATE POLICY read_events_authenticated ON public.trolley_events
    FOR SELECT TO authenticated USING (true);

-- Authenticated users: insert only if user exists
CREATE POLICY insert_events_authenticated ON public.trolley_events
    FOR INSERT TO authenticated
    WITH CHECK (
        EXISTS (SELECT 1 FROM public.users u WHERE u.user_id = trolley_events.user_id)
    );

-- Service role: full access
CREATE POLICY service_full_events ON public.trolley_events
    FOR ALL TO service_role USING (true) WITH CHECK (true);

-- -------------------------------------------------------
-- LOCATIONS, TROLLEYS, USERS — read access for all
-- -------------------------------------------------------

CREATE POLICY read_locations ON public.locations
    FOR SELECT USING (true);

CREATE POLICY read_trolleys ON public.trolleys
    FOR SELECT USING (true);

CREATE POLICY read_users ON public.users
    FOR SELECT USING (true);

-- Service role: full access on supporting tables
CREATE POLICY service_full_locations ON public.locations
    FOR ALL TO service_role USING (true) WITH CHECK (true);

CREATE POLICY service_full_trolleys ON public.trolleys
    FOR ALL TO service_role USING (true) WITH CHECK (true);

CREATE POLICY service_full_users ON public.users
    FOR ALL TO service_role USING (true) WITH CHECK (true);

CREATE POLICY service_full_rewards ON public.reward_ledger
    FOR ALL TO service_role USING (true) WITH CHECK (true);
