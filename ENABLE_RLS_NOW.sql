-- RUN THIS IN SUPABASE SQL EDITOR TO SECURE YOUR TABLES
-- https://supabase.com/dashboard/project/lodmtemrzvmiihfoidrt/sql

-- 1. ENABLE RLS (CRITICAL - YOUR DATA IS EXPOSED WITHOUT THIS!)
ALTER TABLE public.season_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.season_weeks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.weekly_agendas ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.parent_comms ENABLE ROW LEVEL SECURITY;

-- 2. Verify RLS is enabled
SELECT 
    tablename,
    CASE 
        WHEN rowsecurity = true THEN '✅ RLS ENABLED - SECURED'
        ELSE '❌ RLS DISABLED - DATA EXPOSED!'
    END as security_status
FROM 
    pg_tables
WHERE 
    schemaname = 'public'
    AND tablename IN ('season_plans', 'season_weeks', 'weekly_agendas', 'parent_comms')
ORDER BY 
    tablename;

-- After running this, all tables should show ✅ RLS ENABLED