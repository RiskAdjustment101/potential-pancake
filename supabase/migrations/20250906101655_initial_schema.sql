-- Initial schema for FLL Mentor Copilot
-- Created: 2025-09-06
-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Enable Row Level Security
ALTER DATABASE postgres SET "app.jwt_secret" TO 'your-jwt-secret';

-- Season Plans table
CREATE TABLE season_plans (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id TEXT NOT NULL,
    team_name TEXT NOT NULL,
    team_size INTEGER NOT NULL CHECK (team_size > 0),
    meeting_frequency TEXT NOT NULL CHECK (meeting_frequency IN ('weekly', 'bi-weekly')),
    competition_date DATE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Season Weeks table
CREATE TABLE season_weeks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    season_plan_id UUID NOT NULL REFERENCES season_plans(id) ON DELETE CASCADE,
    week_number INTEGER NOT NULL,
    title TEXT NOT NULL,
    description TEXT,
    goals TEXT[] DEFAULT '{}',
    activities TEXT[] DEFAULT '{}',
    supplies_needed TEXT[] DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(season_plan_id, week_number)
);

-- Weekly Agendas table
CREATE TABLE weekly_agendas (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id TEXT NOT NULL,
    season_week_id UUID REFERENCES season_weeks(id) ON DELETE SET NULL,
    meeting_date DATE NOT NULL,
    warmup TEXT,
    build_activity TEXT,
    coding_activity TEXT,
    reflection TEXT,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Parent Communications table
CREATE TABLE parent_comms (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id TEXT NOT NULL,
    season_plan_id UUID REFERENCES season_plans(id) ON DELETE SET NULL,
    subject TEXT NOT NULL,
    content TEXT NOT NULL,
    send_date DATE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes
CREATE INDEX idx_season_plans_user_id ON season_plans(user_id);
CREATE INDEX idx_season_weeks_season_plan_id ON season_weeks(season_plan_id);
CREATE INDEX idx_weekly_agendas_user_id ON weekly_agendas(user_id);
CREATE INDEX idx_weekly_agendas_season_week_id ON weekly_agendas(season_week_id);
CREATE INDEX idx_parent_comms_user_id ON parent_comms(user_id);
CREATE INDEX idx_parent_comms_season_plan_id ON parent_comms(season_plan_id);

-- Enable Row Level Security
ALTER TABLE season_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE season_weeks ENABLE ROW LEVEL SECURITY;
ALTER TABLE weekly_agendas ENABLE ROW LEVEL SECURITY;
ALTER TABLE parent_comms ENABLE ROW LEVEL SECURITY;

-- RLS Policies (using Clerk user IDs)
-- Season Plans policies
CREATE POLICY "Users can view own season plans" ON season_plans
    FOR SELECT USING (auth.jwt() ->> 'sub' = user_id);

CREATE POLICY "Users can insert own season plans" ON season_plans
    FOR INSERT WITH CHECK (auth.jwt() ->> 'sub' = user_id);

CREATE POLICY "Users can update own season plans" ON season_plans
    FOR UPDATE USING (auth.jwt() ->> 'sub' = user_id);

CREATE POLICY "Users can delete own season plans" ON season_plans
    FOR DELETE USING (auth.jwt() ->> 'sub' = user_id);

-- Season Weeks policies (inherit from season plan)
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

-- Weekly Agendas policies
CREATE POLICY "Users can view own agendas" ON weekly_agendas
    FOR SELECT USING (auth.jwt() ->> 'sub' = user_id);

CREATE POLICY "Users can insert own agendas" ON weekly_agendas
    FOR INSERT WITH CHECK (auth.jwt() ->> 'sub' = user_id);

CREATE POLICY "Users can update own agendas" ON weekly_agendas
    FOR UPDATE USING (auth.jwt() ->> 'sub' = user_id);

CREATE POLICY "Users can delete own agendas" ON weekly_agendas
    FOR DELETE USING (auth.jwt() ->> 'sub' = user_id);

-- Parent Comms policies
CREATE POLICY "Users can view own parent comms" ON parent_comms
    FOR SELECT USING (auth.jwt() ->> 'sub' = user_id);

CREATE POLICY "Users can insert own parent comms" ON parent_comms
    FOR INSERT WITH CHECK (auth.jwt() ->> 'sub' = user_id);

CREATE POLICY "Users can update own parent comms" ON parent_comms
    FOR UPDATE USING (auth.jwt() ->> 'sub' = user_id);

CREATE POLICY "Users can delete own parent comms" ON parent_comms
    FOR DELETE USING (auth.jwt() ->> 'sub' = user_id);

-- Function to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create triggers for updated_at
CREATE TRIGGER update_season_plans_updated_at BEFORE UPDATE ON season_plans 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_season_weeks_updated_at BEFORE UPDATE ON season_weeks 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_weekly_agendas_updated_at BEFORE UPDATE ON weekly_agendas 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_parent_comms_updated_at BEFORE UPDATE ON parent_comms 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();