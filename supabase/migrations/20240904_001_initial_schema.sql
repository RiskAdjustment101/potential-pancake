-- Initial schema for FLL Mentor Copilot
-- Migration: 20240904_001_initial_schema

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

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

-- Create indexes for performance
CREATE INDEX idx_season_plans_user_id ON season_plans(user_id);
CREATE INDEX idx_season_weeks_season_plan_id ON season_weeks(season_plan_id);
CREATE INDEX idx_weekly_agendas_user_id ON weekly_agendas(user_id);
CREATE INDEX idx_weekly_agendas_season_week_id ON weekly_agendas(season_week_id);
CREATE INDEX idx_parent_comms_user_id ON parent_comms(user_id);
CREATE INDEX idx_parent_comms_season_plan_id ON parent_comms(season_plan_id);

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