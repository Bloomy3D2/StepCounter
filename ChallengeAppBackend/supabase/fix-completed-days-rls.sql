-- Fix RLS for completed_days INSERT
-- Run in Supabase SQL Editor.
--
-- Symptom in app:
--   "new row violates row-level security policy for table \"completed_days\""
--
-- Root cause:
--   RLS enabled on public.completed_days, but INSERT policy is missing.

-- Ensure RLS is enabled (idempotent)
ALTER TABLE public.completed_days ENABLE ROW LEVEL SECURITY;

-- Allow authenticated user to insert only for their own user_challenges
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename  = 'completed_days'
      AND policyname = 'Users can insert own completed days'
  ) THEN
    EXECUTE $policy$
      CREATE POLICY "Users can insert own completed days"
        ON public.completed_days FOR INSERT
        WITH CHECK (
          EXISTS (
            SELECT 1 FROM public.user_challenges
            WHERE id = completed_days.user_challenge_id
              AND user_id = auth.uid()
          )
        );
    $policy$;
  END IF;
END $$;

