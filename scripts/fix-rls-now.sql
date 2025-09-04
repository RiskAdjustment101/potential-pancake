-- IMMEDIATE FIX: Enable RLS on remaining tables
-- Run this in Supabase SQL Editor NOW

-- Force enable RLS on all tables (even if already enabled)
ALTER TABLE public.season_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.season_weeks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.weekly_agendas ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.parent_comms ENABLE ROW LEVEL SECURITY;

-- Verify RLS status
SELECT 
    tablename,
    CASE 
        WHEN rowsecurity = true THEN '✅ RLS Enabled'
        ELSE '❌ RLS NOT Enabled'
    END as status
FROM 
    pg_tables
WHERE 
    schemaname = 'public'
    AND tablename IN ('season_plans', 'season_weeks', 'weekly_agendas', 'parent_comms')
ORDER BY 
    tablename;