-- Row Level Security Policies
-- Migration: 20240904_002_rls_policies

-- Enable Row Level Security on all tables
ALTER TABLE season_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE season_weeks ENABLE ROW LEVEL SECURITY;
ALTER TABLE weekly_agendas ENABLE ROW LEVEL SECURITY;
ALTER TABLE parent_comms ENABLE ROW LEVEL SECURITY;

-- Season Plans RLS Policies (using Clerk user IDs)
CREATE POLICY "Users can view own season plans" ON season_plans
    FOR SELECT USING (auth.jwt() ->> 'sub' = user_id);

CREATE POLICY "Users can insert own season plans" ON season_plans
    FOR INSERT WITH CHECK (auth.jwt() ->> 'sub' = user_id);

CREATE POLICY "Users can update own season plans" ON season_plans
    FOR UPDATE USING (auth.jwt() ->> 'sub' = user_id);

CREATE POLICY "Users can delete own season plans" ON season_plans
    FOR DELETE USING (auth.jwt() ->> 'sub' = user_id);

-- Season Weeks RLS Policies (inherit permission from season plan)
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

-- Weekly Agendas RLS Policies
CREATE POLICY "Users can view own agendas" ON weekly_agendas
    FOR SELECT USING (auth.jwt() ->> 'sub' = user_id);

CREATE POLICY "Users can insert own agendas" ON weekly_agendas
    FOR INSERT WITH CHECK (auth.jwt() ->> 'sub' = user_id);

CREATE POLICY "Users can update own agendas" ON weekly_agendas
    FOR UPDATE USING (auth.jwt() ->> 'sub' = user_id);

CREATE POLICY "Users can delete own agendas" ON weekly_agendas
    FOR DELETE USING (auth.jwt() ->> 'sub' = user_id);

-- Parent Communications RLS Policies
CREATE POLICY "Users can view own parent comms" ON parent_comms
    FOR SELECT USING (auth.jwt() ->> 'sub' = user_id);

CREATE POLICY "Users can insert own parent comms" ON parent_comms
    FOR INSERT WITH CHECK (auth.jwt() ->> 'sub' = user_id);

CREATE POLICY "Users can update own parent comms" ON parent_comms
    FOR UPDATE USING (auth.jwt() ->> 'sub' = user_id);

CREATE POLICY "Users can delete own parent comms" ON parent_comms
    FOR DELETE USING (auth.jwt() ->> 'sub' = user_id);