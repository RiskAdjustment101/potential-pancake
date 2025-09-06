-- Complete Database Reset and Clean Setup
-- This migration removes everything and rebuilds from scratch

-- Drop all existing tables, policies, functions, triggers
DROP SCHEMA public CASCADE;
CREATE SCHEMA public;
GRANT USAGE ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO public;

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

-- Create basic indexes
CREATE INDEX idx_user_profiles_clerk_id ON user_profiles(clerk_user_id);
CREATE INDEX idx_user_profiles_email ON user_profiles(email);
CREATE INDEX idx_team_mentors_team_id ON team_mentors(team_id);
CREATE INDEX idx_team_mentors_user_id ON team_mentors(user_id);

-- Enable RLS with simple policies
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE mentor_teams ENABLE ROW LEVEL SECURITY;  
ALTER TABLE team_mentors ENABLE ROW LEVEL SECURITY;

-- Allow all authenticated users (we'll tighten this later)
CREATE POLICY "authenticated_users_all" ON user_profiles FOR ALL 
    USING (auth.jwt() ->> 'sub' IS NOT NULL);

CREATE POLICY "authenticated_users_all" ON mentor_teams FOR ALL 
    USING (auth.jwt() ->> 'sub' IS NOT NULL);

CREATE POLICY "authenticated_users_all" ON team_mentors FOR ALL 
    USING (auth.jwt() ->> 'sub' IS NOT NULL);