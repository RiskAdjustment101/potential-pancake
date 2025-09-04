-- 🚨 CRITICAL: Run this IMMEDIATELY in Supabase SQL Editor
-- This enables security on your tables
-- Go to: https://supabase.com/dashboard/project/lodmtemrzvmiihfoidrt/sql

-- 1. ENABLE ROW LEVEL SECURITY (Currently disabled and exposing data!)
ALTER TABLE public.season_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.season_weeks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.weekly_agendas ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.parent_comms ENABLE ROW LEVEL SECURITY;

-- 2. CREATE SECURITY POLICIES
-- Season Plans - Users can only see/edit their own
CREATE POLICY IF NOT EXISTS "Users can view own season plans" ON season_plans
    FOR SELECT USING (auth.jwt() ->> 'sub' = user_id);

CREATE POLICY IF NOT EXISTS "Users can insert own season plans" ON season_plans
    FOR INSERT WITH CHECK (auth.jwt() ->> 'sub' = user_id);

CREATE POLICY IF NOT EXISTS "Users can update own season plans" ON season_plans
    FOR UPDATE USING (auth.jwt() ->> 'sub' = user_id);

CREATE POLICY IF NOT EXISTS "Users can delete own season plans" ON season_plans
    FOR DELETE USING (auth.jwt() ->> 'sub' = user_id);

-- Season Weeks - Inherit from parent season plan
CREATE POLICY IF NOT EXISTS "Users can view own season weeks" ON season_weeks
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM season_plans 
            WHERE season_plans.id = season_weeks.season_plan_id 
            AND season_plans.user_id = auth.jwt() ->> 'sub'
        )
    );

CREATE POLICY IF NOT EXISTS "Users can insert own season weeks" ON season_weeks
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM season_plans 
            WHERE season_plans.id = season_weeks.season_plan_id 
            AND season_plans.user_id = auth.jwt() ->> 'sub'
        )
    );

CREATE POLICY IF NOT EXISTS "Users can update own season weeks" ON season_weeks
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM season_plans 
            WHERE season_plans.id = season_weeks.season_plan_id 
            AND season_plans.user_id = auth.jwt() ->> 'sub'
        )
    );

CREATE POLICY IF NOT EXISTS "Users can delete own season weeks" ON season_weeks
    FOR DELETE USING (
        EXISTS (
            SELECT 1 FROM season_plans 
            WHERE season_plans.id = season_weeks.season_plan_id 
            AND season_plans.user_id = auth.jwt() ->> 'sub'
        )
    );

-- Weekly Agendas - Users can only see/edit their own
CREATE POLICY IF NOT EXISTS "Users can view own agendas" ON weekly_agendas
    FOR SELECT USING (auth.jwt() ->> 'sub' = user_id);

CREATE POLICY IF NOT EXISTS "Users can insert own agendas" ON weekly_agendas
    FOR INSERT WITH CHECK (auth.jwt() ->> 'sub' = user_id);

CREATE POLICY IF NOT EXISTS "Users can update own agendas" ON weekly_agendas
    FOR UPDATE USING (auth.jwt() ->> 'sub' = user_id);

CREATE POLICY IF NOT EXISTS "Users can delete own agendas" ON weekly_agendas
    FOR DELETE USING (auth.jwt() ->> 'sub' = user_id);

-- Parent Communications - Users can only see/edit their own
CREATE POLICY IF NOT EXISTS "Users can view own parent comms" ON parent_comms
    FOR SELECT USING (auth.jwt() ->> 'sub' = user_id);

CREATE POLICY IF NOT EXISTS "Users can insert own parent comms" ON parent_comms
    FOR INSERT WITH CHECK (auth.jwt() ->> 'sub' = user_id);

CREATE POLICY IF NOT EXISTS "Users can update own parent comms" ON parent_comms
    FOR UPDATE USING (auth.jwt() ->> 'sub' = user_id);

CREATE POLICY IF NOT EXISTS "Users can delete own parent comms" ON parent_comms
    FOR DELETE USING (auth.jwt() ->> 'sub' = user_id);

-- 3. FIX FUNCTION SECURITY WARNING
DROP FUNCTION IF EXISTS update_updated_at_column() CASCADE;

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER 
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;

-- Recreate triggers
CREATE TRIGGER update_season_plans_updated_at 
    BEFORE UPDATE ON season_plans 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_season_weeks_updated_at 
    BEFORE UPDATE ON season_weeks 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_weekly_agendas_updated_at 
    BEFORE UPDATE ON weekly_agendas 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_parent_comms_updated_at 
    BEFORE UPDATE ON parent_comms 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- 4. VERIFY EVERYTHING IS SECURED
SELECT 
    tablename,
    CASE 
        WHEN rowsecurity = true THEN '✅ SECURED'
        ELSE '❌ NOT SECURED - DATA EXPOSED!'
    END as status
FROM 
    pg_tables
WHERE 
    schemaname = 'public'
    AND tablename IN ('season_plans', 'season_weeks', 'weekly_agendas', 'parent_comms')
ORDER BY 
    tablename;

-- You should see:
-- season_plans      ✅ SECURED
-- season_weeks      ✅ SECURED
-- weekly_agendas    ✅ SECURED
-- parent_comms      ✅ SECURED