-- ============================================================
-- FOLD TROLLEY TRACKER — Database Schema (v2)
-- PostgreSQL 17 (Supabase)
-- Updated: May 2026
-- Changes: Added condition, source, dwell_minutes to trolley_events
--          Added restock_events table
--          Added GPS coordinates to all locations
-- ============================================================

-- LOCATIONS
CREATE TABLE public.locations (
    location_id   BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    location_name VARCHAR NOT NULL UNIQUE,
    store_code    VARCHAR,
    zone          VARCHAR,
    latitude      NUMERIC,
    longitude     NUMERIC,
    target_min    INTEGER NOT NULL DEFAULT 0,
    target_max    INTEGER NOT NULL DEFAULT 9999,
    is_active     BOOLEAN NOT NULL DEFAULT TRUE,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- TROLLEYS
CREATE TABLE public.trolleys (
    trolley_id          VARCHAR PRIMARY KEY,
    status              VARCHAR NOT NULL DEFAULT 'active',
    current_location_id BIGINT REFERENCES public.locations(location_id),
    last_action         VARCHAR CHECK (last_action IN ('pickup', 'dropoff')),
    last_event_ts       TIMESTAMPTZ,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- USERS
CREATE TABLE public.users (
    user_id    VARCHAR PRIMARY KEY,
    source     VARCHAR NOT NULL DEFAULT 'shopback',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- TROLLEY EVENTS
CREATE TABLE public.trolley_events (
    event_id    BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    trolley_id  VARCHAR NOT NULL REFERENCES public.trolleys(trolley_id),
    user_id     VARCHAR NOT NULL REFERENCES public.users(user_id),
    location_id BIGINT NOT NULL REFERENCES public.locations(location_id),
    action      VARCHAR NOT NULL CHECK (action IN ('pickup', 'dropoff')),
    event_ts    TIMESTAMPTZ NOT NULL,
    latitude    NUMERIC,
    longitude   NUMERIC,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- REWARD LEDGER
CREATE TABLE public.reward_ledger (
    reward_id       BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id         VARCHAR NOT NULL REFERENCES public.users(user_id),
    trolley_id      VARCHAR NOT NULL REFERENCES public.trolleys(trolley_id),
    points          INTEGER NOT NULL,
    reason          VARCHAR NOT NULL,
    source_event_id BIGINT REFERENCES public.trolley_events(event_id),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
