-- Analytics events (minimal internal analytics, "almost free")
-- Run in Supabase SQL Editor.
--
-- What you get:
-- - A single events table (JSONB props)
-- - RLS: users can INSERT/SELECT only their own events
-- - Indexes for DAU/retention/funnels
--
-- Notes:
-- - Service role bypasses RLS (so you can build global business reports).
-- - App code inserts with the authenticated user token.

CREATE TABLE IF NOT EXISTS public.analytics_events (
  id           BIGSERIAL PRIMARY KEY,
  user_id      UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  session_id   UUID NOT NULL,
  event_name   TEXT NOT NULL,
  challenge_id BIGINT REFERENCES public.challenges(id) ON DELETE SET NULL,
  amount       NUMERIC(10, 2),
  props        JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes (idempotent)
CREATE INDEX IF NOT EXISTS idx_analytics_events_created_at
  ON public.analytics_events(created_at DESC);

CREATE INDEX IF NOT EXISTS idx_analytics_events_user_created_at
  ON public.analytics_events(user_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_analytics_events_event_created_at
  ON public.analytics_events(event_name, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_analytics_events_challenge_created_at
  ON public.analytics_events(challenge_id, created_at DESC)
  WHERE challenge_id IS NOT NULL;

-- RLS
ALTER TABLE public.analytics_events ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  -- SELECT own
  IF NOT EXISTS (
    SELECT 1
    FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename  = 'analytics_events'
      AND policyname = 'Users can view own analytics events'
  ) THEN
    EXECUTE $policy$
      CREATE POLICY "Users can view own analytics events"
        ON public.analytics_events
        FOR SELECT
        USING (user_id = auth.uid());
    $policy$;
  END IF;

  -- INSERT own
  IF NOT EXISTS (
    SELECT 1
    FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename  = 'analytics_events'
      AND policyname = 'Users can insert own analytics events'
  ) THEN
    EXECUTE $policy$
      CREATE POLICY "Users can insert own analytics events"
        ON public.analytics_events
        FOR INSERT
        WITH CHECK (user_id = auth.uid());
    $policy$;
  END IF;
END $$;

-- No UPDATE/DELETE policies on purpose.
-- Analytics should be append-only from the client side.
