-- Complete Mentor System Schema
-- Implements head coach, assistant mentors, invites, approvals, and succession

-- 1. User Profiles (all users, whether head coaches or assistants)
CREATE TABLE IF NOT EXISTS user_profiles (
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

-- 2. Mentor Teams (the FLL teams)
CREATE TABLE IF NOT EXISTS mentor_teams (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    team_number TEXT UNIQUE, -- Official FLL team number
    team_name TEXT NOT NULL,
    team_size INTEGER,
    age_group TEXT CHECK (age_group IN ('elementary', 'middle', 'mixed')),
    meeting_location TEXT,
    meeting_schedule TEXT, -- "Tuesdays 4-6pm, Saturdays 10am-12pm"
    competition_region TEXT,
    competition_date DATE,
    season_year INTEGER DEFAULT EXTRACT(YEAR FROM CURRENT_DATE),
    is_active BOOLEAN DEFAULT TRUE,
    created_by_user_id TEXT NOT NULL, -- Clerk ID of creator
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. Team Mentors (links mentors to teams with roles)
CREATE TABLE IF NOT EXISTS team_mentors (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    team_id UUID NOT NULL REFERENCES mentor_teams(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
    role TEXT NOT NULL CHECK (role IN ('head_coach', 'assistant_mentor')),
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_active BOOLEAN DEFAULT TRUE,
    UNIQUE(team_id, user_id)
);

-- 4. Mentor Invites (pending invitations)
CREATE TABLE IF NOT EXISTS mentor_invites (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    team_id UUID NOT NULL REFERENCES mentor_teams(id) ON DELETE CASCADE,
    invited_email TEXT NOT NULL,
    invited_by_user_id UUID NOT NULL REFERENCES user_profiles(id),
    invite_token TEXT UNIQUE DEFAULT gen_random_uuid()::TEXT,
    role TEXT NOT NULL CHECK (role IN ('head_coach', 'assistant_mentor')),
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'declined', 'expired')),
    expires_at TIMESTAMP WITH TIME ZONE DEFAULT (NOW() + INTERVAL '7 days'),
    accepted_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 5. Team Succession Plans
CREATE TABLE IF NOT EXISTS team_succession (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    team_id UUID NOT NULL REFERENCES mentor_teams(id) ON DELETE CASCADE,
    current_head_coach_id UUID NOT NULL REFERENCES user_profiles(id),
    designated_successor_id UUID REFERENCES user_profiles(id),
    succession_notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(team_id)
);

-- 6. Agenda Approvals (track draft/approved status)
CREATE TABLE IF NOT EXISTS agenda_approvals (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    agenda_id UUID NOT NULL REFERENCES weekly_agendas(id) ON DELETE CASCADE,
    created_by_user_id UUID NOT NULL REFERENCES user_profiles(id),
    status TEXT DEFAULT 'draft' CHECK (status IN ('draft', 'pending_review', 'approved', 'rejected')),
    approved_by_user_id UUID REFERENCES user_profiles(id),
    approval_notes TEXT,
    approved_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 7. Communication Approvals
CREATE TABLE IF NOT EXISTS communication_approvals (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    communication_id UUID NOT NULL REFERENCES parent_comms(id) ON DELETE CASCADE,
    created_by_user_id UUID NOT NULL REFERENCES user_profiles(id),
    status TEXT DEFAULT 'draft' CHECK (status IN ('draft', 'pending_review', 'approved', 'sent')),
    approved_by_user_id UUID REFERENCES user_profiles(id),
    approval_notes TEXT,
    approved_at TIMESTAMP WITH TIME ZONE,
    sent_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Update existing tables to link with new system
ALTER TABLE season_plans ADD COLUMN IF NOT EXISTS team_id UUID REFERENCES mentor_teams(id);
ALTER TABLE weekly_agendas ADD COLUMN IF NOT EXISTS team_id UUID REFERENCES mentor_teams(id);
ALTER TABLE parent_comms ADD COLUMN IF NOT EXISTS team_id UUID REFERENCES mentor_teams(id);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_user_profiles_clerk_id ON user_profiles(clerk_user_id);
CREATE INDEX IF NOT EXISTS idx_user_profiles_email ON user_profiles(email);
CREATE INDEX IF NOT EXISTS idx_team_mentors_team_id ON team_mentors(team_id);
CREATE INDEX IF NOT EXISTS idx_team_mentors_user_id ON team_mentors(user_id);
CREATE INDEX IF NOT EXISTS idx_mentor_invites_team_id ON mentor_invites(team_id);
CREATE INDEX IF NOT EXISTS idx_mentor_invites_token ON mentor_invites(invite_token);
CREATE INDEX IF NOT EXISTS idx_mentor_invites_email ON mentor_invites(invited_email);

-- Enable RLS on all tables
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE mentor_teams ENABLE ROW LEVEL SECURITY;
ALTER TABLE team_mentors ENABLE ROW LEVEL SECURITY;
ALTER TABLE mentor_invites ENABLE ROW LEVEL SECURITY;
ALTER TABLE team_succession ENABLE ROW LEVEL SECURITY;
ALTER TABLE agenda_approvals ENABLE ROW LEVEL SECURITY;
ALTER TABLE communication_approvals ENABLE ROW LEVEL SECURITY;

-- RLS Policies

-- User Profiles: Users can manage their own profile
CREATE POLICY "Users can view own profile" ON user_profiles
    FOR SELECT USING (clerk_user_id = auth.jwt() ->> 'sub');
CREATE POLICY "Users can update own profile" ON user_profiles
    FOR UPDATE USING (clerk_user_id = auth.jwt() ->> 'sub');
CREATE POLICY "Users can insert own profile" ON user_profiles
    FOR INSERT WITH CHECK (clerk_user_id = auth.jwt() ->> 'sub');

-- Mentor Teams: Viewable by team members
CREATE POLICY "Team members can view team" ON mentor_teams
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM team_mentors tm
            JOIN user_profiles up ON tm.user_id = up.id
            WHERE tm.team_id = mentor_teams.id
            AND up.clerk_user_id = auth.jwt() ->> 'sub'
            AND tm.is_active = TRUE
        )
    );

-- Team Mentors: Viewable by team members
CREATE POLICY "Team members can view mentor list" ON team_mentors
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM team_mentors tm2
            JOIN user_profiles up ON tm2.user_id = up.id
            WHERE tm2.team_id = team_mentors.team_id
            AND up.clerk_user_id = auth.jwt() ->> 'sub'
            AND tm2.is_active = TRUE
        )
    );

-- Only head coaches can add/remove mentors
CREATE POLICY "Head coaches can manage team mentors" ON team_mentors
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM team_mentors tm
            JOIN user_profiles up ON tm.user_id = up.id
            WHERE tm.team_id = team_mentors.team_id
            AND up.clerk_user_id = auth.jwt() ->> 'sub'
            AND tm.role = 'head_coach'
            AND tm.is_active = TRUE
        )
    );

-- Invites: Head coaches can create, invitees can view their invites
CREATE POLICY "Head coaches can create invites" ON mentor_invites
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM team_mentors tm
            JOIN user_profiles up ON tm.user_id = up.id
            WHERE tm.team_id = mentor_invites.team_id
            AND up.clerk_user_id = auth.jwt() ->> 'sub'
            AND tm.role = 'head_coach'
            AND tm.is_active = TRUE
        )
    );

CREATE POLICY "Users can view invites sent to them" ON mentor_invites
    FOR SELECT USING (
        invited_email = (SELECT email FROM user_profiles WHERE clerk_user_id = auth.jwt() ->> 'sub')
    );

-- Triggers for updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_user_profiles_updated_at BEFORE UPDATE ON user_profiles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_mentor_teams_updated_at BEFORE UPDATE ON mentor_teams
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_team_succession_updated_at BEFORE UPDATE ON team_succession
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();