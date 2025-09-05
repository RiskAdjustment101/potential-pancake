-- Create RLS Policies for all tables
-- Run this in Supabase SQL Editor: https://supabase.com/dashboard/project/lodmtemrzvmiihfoidrt/sql

-- Drop existing policies if any (to start fresh)
DROP POLICY IF EXISTS "Users can view own season plans" ON season_plans;
DROP POLICY IF EXISTS "Users can insert own season plans" ON season_plans;
DROP POLICY IF EXISTS "Users can update own season plans" ON season_plans;
DROP POLICY IF EXISTS "Users can delete own season plans" ON season_plans;

DROP POLICY IF EXISTS "Users can view own season weeks" ON season_weeks;
DROP POLICY IF EXISTS "Users can insert own season weeks" ON season_weeks;
DROP POLICY IF EXISTS "Users can update own season weeks" ON season_weeks;
DROP POLICY IF EXISTS "Users can delete own season weeks" ON season_weeks;

DROP POLICY IF EXISTS "Users can view own agendas" ON weekly_agendas;
DROP POLICY IF EXISTS "Users can insert own agendas" ON weekly_agendas;
DROP POLICY IF EXISTS "Users can update own agendas" ON weekly_agendas;
DROP POLICY IF EXISTS "Users can delete own agendas" ON weekly_agendas;

DROP POLICY IF EXISTS "Users can view own parent comms" ON parent_comms;
DROP POLICY IF EXISTS "Users can insert own parent comms" ON parent_comms;
DROP POLICY IF EXISTS "Users can update own parent comms" ON parent_comms;
DROP POLICY IF EXISTS "Users can delete own parent comms" ON parent_comms;

-- Create policies for season_plans
CREATE POLICY "Users can view own season plans" ON season_plans
    FOR SELECT USING (auth.jwt() ->> 'sub' = user_id);

CREATE POLICY "Users can insert own season plans" ON season_plans
    FOR INSERT WITH CHECK (auth.jwt() ->> 'sub' = user_id);

CREATE POLICY "Users can update own season plans" ON season_plans
    FOR UPDATE USING (auth.jwt() ->> 'sub' = user_id);

CREATE POLICY "Users can delete own season plans" ON season_plans
    FOR DELETE USING (auth.jwt() ->> 'sub' = user_id);

-- Create policies for season_weeks (inherit from parent season_plan)
CREATE POLICY "Users can view own season weeks" ON season_weeks
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM season_plans 
            WHERE season_plans.id = season_weeks.season_plan_id 
            AND season_plans.user_id = auth.jwt() ->> 'sub'
        )
    );

CREATE POLICY "Users can insert own season weeks" ON season_weeks
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM season_plans 
            WHERE season_plans.id = season_weeks.season_plan_id 
            AND season_plans.user_id = auth.jwt() ->> 'sub'
        )
    );

CREATE POLICY "Users can update own season weeks" ON season_weeks
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM season_plans 
            WHERE season_plans.id = season_weeks.season_plan_id 
            AND season_plans.user_id = auth.jwt() ->> 'sub'
        )
    );

CREATE POLICY "Users can delete own season weeks" ON season_weeks
    FOR DELETE USING (
        EXISTS (
            SELECT 1 FROM season_plans 
            WHERE season_plans.id = season_weeks.season_plan_id 
            AND season_plans.user_id = auth.jwt() ->> 'sub'
        )
    );

-- Create policies for weekly_agendas
CREATE POLICY "Users can view own agendas" ON weekly_agendas
    FOR SELECT USING (auth.jwt() ->> 'sub' = user_id);

CREATE POLICY "Users can insert own agendas" ON weekly_agendas
    FOR INSERT WITH CHECK (auth.jwt() ->> 'sub' = user_id);

CREATE POLICY "Users can update own agendas" ON weekly_agendas
    FOR UPDATE USING (auth.jwt() ->> 'sub' = user_id);

CREATE POLICY "Users can delete own agendas" ON weekly_agendas
    FOR DELETE USING (auth.jwt() ->> 'sub' = user_id);

-- Create policies for parent_comms
CREATE POLICY "Users can view own parent comms" ON parent_comms
    FOR SELECT USING (auth.jwt() ->> 'sub' = user_id);

CREATE POLICY "Users can insert own parent comms" ON parent_comms
    FOR INSERT WITH CHECK (auth.jwt() ->> 'sub' = user_id);

CREATE POLICY "Users can update own parent comms" ON parent_comms
    FOR UPDATE USING (auth.jwt() ->> 'sub' = user_id);

CREATE POLICY "Users can delete own parent comms" ON parent_comms
    FOR DELETE USING (auth.jwt() ->> 'sub' = user_id);

-- Verify policies were created
SELECT 
    tablename,
    policyname,
    permissive,
    roles,
    cmd
FROM pg_policies
WHERE schemaname = 'public'
    AND tablename IN ('season_plans', 'season_weeks', 'weekly_agendas', 'parent_comms')
ORDER BY tablename, policyname;

-- Count policies per table (should be 4 for each table)
SELECT 
    tablename,
    COUNT(*) as policy_count,
    CASE 
        WHEN COUNT(*) = 4 THEN '✅ Fully secured (4 policies)'
        ELSE '⚠️ Missing policies'
    END as status
FROM pg_policies
WHERE schemaname = 'public'
    AND tablename IN ('season_plans', 'season_weeks', 'weekly_agendas', 'parent_comms')
GROUP BY tablename
ORDER BY tablename;