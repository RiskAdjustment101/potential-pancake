-- 🚨 URGENT: Your tables are NOT secured! Run this NOW
-- Go to: https://supabase.com/dashboard/project/lodmtemrzvmiihfoidrt/sql

-- Enable RLS on ALL tables (this is CRITICAL for security)
ALTER TABLE public.season_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.season_weeks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.weekly_agendas ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.parent_comms ENABLE ROW LEVEL SECURITY;

-- Verify RLS is enabled
SELECT 
    tablename,
    CASE 
        WHEN rowsecurity = true THEN '✅ SECURED with RLS'
        ELSE '❌ NOT SECURED - DATA EXPOSED!'
    END as security_status
FROM 
    pg_tables
WHERE 
    schemaname = 'public'
    AND tablename IN ('season_plans', 'season_weeks', 'weekly_agendas', 'parent_comms')
ORDER BY 
    tablename;

-- After running, all should show ✅ SECURED