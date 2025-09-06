-- Clean Mentor System Schema
-- Simple, reliable schema without complex RLS

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. User Profiles (all mentors)
CREATE TABLE user_profiles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    clerk_user_id TEXT UNIQUE NOT NULL,
    email TEXT UNIQUE NOT NULL,
    full_name TEXT NOT NULL,
    phone TEXT,
    years_mentoring INTEGER DEFAULT 0,
    bio TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Mentor Teams (FLL teams)
CREATE TABLE mentor_teams (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    team_number TEXT,
    team_name TEXT NOT NULL,
    team_size INTEGER,
    age_group TEXT CHECK (age_group IN ('elementary', 'middle', 'mixed')),
    meeting_location TEXT,
    meeting_schedule TEXT,
    competition_region TEXT,
    competition_date DATE,
    season_year INTEGER DEFAULT EXTRACT(YEAR FROM CURRENT_DATE),
    is_active BOOLEAN DEFAULT TRUE,
    created_by_user_id TEXT NOT NULL, -- Clerk ID
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. Team Mentors (links mentors to teams with roles)
CREATE TABLE team_mentors (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    team_id UUID NOT NULL REFERENCES mentor_teams(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
    role TEXT NOT NULL CHECK (role IN ('head_coach', 'assistant_mentor')),
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_active BOOLEAN DEFAULT TRUE,
    UNIQUE(team_id, user_id)
);

-- 4. Season Plans (linked to teams)
CREATE TABLE season_plans (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    team_id UUID NOT NULL REFERENCES mentor_teams(id) ON DELETE CASCADE,
    user_id TEXT NOT NULL, -- Clerk ID of creator
    team_name TEXT NOT NULL,
    team_size INTEGER NOT NULL CHECK (team_size > 0),
    meeting_frequency TEXT NOT NULL CHECK (meeting_frequency IN ('weekly', 'bi-weekly')),
    competition_date DATE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 5. Season Weeks
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

-- 6. Weekly Agendas
CREATE TABLE weekly_agendas (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    team_id UUID REFERENCES mentor_teams(id) ON DELETE CASCADE,
    user_id TEXT NOT NULL, -- Clerk ID of creator
    season_week_id UUID REFERENCES season_weeks(id) ON DELETE SET NULL,
    meeting_date DATE NOT NULL,
    warmup TEXT,
    build_activity TEXT,
    coding_activity TEXT,
    reflection TEXT,
    notes TEXT,
    status TEXT DEFAULT 'draft' CHECK (status IN ('draft', 'approved')),
    approved_by TEXT, -- Clerk ID of approver
    approved_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 7. Parent Communications
CREATE TABLE parent_comms (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    team_id UUID REFERENCES mentor_teams(id) ON DELETE CASCADE,
    user_id TEXT NOT NULL, -- Clerk ID of creator
    season_plan_id UUID REFERENCES season_plans(id) ON DELETE SET NULL,
    subject TEXT NOT NULL,
    content TEXT NOT NULL,
    send_date DATE,
    status TEXT DEFAULT 'draft' CHECK (status IN ('draft', 'approved', 'sent')),
    approved_by TEXT, -- Clerk ID of approver
    approved_at TIMESTAMP WITH TIME ZONE,
    sent_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for performance
CREATE INDEX idx_user_profiles_clerk_id ON user_profiles(clerk_user_id);
CREATE INDEX idx_user_profiles_email ON user_profiles(email);
CREATE INDEX idx_team_mentors_team_id ON team_mentors(team_id);
CREATE INDEX idx_team_mentors_user_id ON team_mentors(user_id);
CREATE INDEX idx_season_plans_team_id ON season_plans(team_id);
CREATE INDEX idx_season_plans_user_id ON season_plans(user_id);
CREATE INDEX idx_season_weeks_season_plan_id ON season_weeks(season_plan_id);
CREATE INDEX idx_weekly_agendas_team_id ON weekly_agendas(team_id);
CREATE INDEX idx_weekly_agendas_user_id ON weekly_agendas(user_id);
CREATE INDEX idx_parent_comms_team_id ON parent_comms(team_id);
CREATE INDEX idx_parent_comms_user_id ON parent_comms(user_id);

-- Enable Row Level Security (simple policies)
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE mentor_teams ENABLE ROW LEVEL SECURITY;
ALTER TABLE team_mentors ENABLE ROW LEVEL SECURITY;
ALTER TABLE season_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE season_weeks ENABLE ROW LEVEL SECURITY;
ALTER TABLE weekly_agendas ENABLE ROW LEVEL SECURITY;
ALTER TABLE parent_comms ENABLE ROW LEVEL SECURITY;

-- Simple RLS Policies (allow all for now, can tighten later)
CREATE POLICY "Allow authenticated users" ON user_profiles FOR ALL 
    USING (auth.jwt() ->> 'sub' IS NOT NULL);

CREATE POLICY "Allow authenticated users" ON mentor_teams FOR ALL 
    USING (auth.jwt() ->> 'sub' IS NOT NULL);

CREATE POLICY "Allow authenticated users" ON team_mentors FOR ALL 
    USING (auth.jwt() ->> 'sub' IS NOT NULL);

CREATE POLICY "Allow authenticated users" ON season_plans FOR ALL 
    USING (auth.jwt() ->> 'sub' IS NOT NULL);

CREATE POLICY "Allow authenticated users" ON season_weeks FOR ALL 
    USING (auth.jwt() ->> 'sub' IS NOT NULL);

CREATE POLICY "Allow authenticated users" ON weekly_agendas FOR ALL 
    USING (auth.jwt() ->> 'sub' IS NOT NULL);

CREATE POLICY "Allow authenticated users" ON parent_comms FOR ALL 
    USING (auth.jwt() ->> 'sub' IS NOT NULL);

-- Simple trigger function for updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create triggers for updated_at
CREATE TRIGGER update_user_profiles_updated_at BEFORE UPDATE ON user_profiles 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_mentor_teams_updated_at BEFORE UPDATE ON mentor_teams 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_season_plans_updated_at BEFORE UPDATE ON season_plans 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_season_weeks_updated_at BEFORE UPDATE ON season_weeks 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_weekly_agendas_updated_at BEFORE UPDATE ON weekly_agendas 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_parent_comms_updated_at BEFORE UPDATE ON parent_comms 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();