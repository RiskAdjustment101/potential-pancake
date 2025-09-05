-- Migration: 20240905000003_mentor_team_foundation
-- Creates the multi-mentor team system with role-based permissions

-- Mentors table (individual mentor profiles)
CREATE TABLE IF NOT EXISTS mentors (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    clerk_user_id TEXT UNIQUE NOT NULL,
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    email TEXT NOT NULL,
    phone TEXT,
    
    -- Professional Info
    organization TEXT, -- School, community center, etc.
    role_title TEXT, -- Teacher, parent, engineer, etc.
    
    -- FLL Experience
    years_coaching INTEGER DEFAULT 0,
    experience_level TEXT CHECK (experience_level IN ('beginner', 'intermediate', 'advanced')) DEFAULT 'beginner',
    previous_seasons TEXT[] DEFAULT '{}', -- Array of years coached
    
    -- Location & Preferences  
    location_city TEXT,
    location_state TEXT,
    location_country TEXT DEFAULT 'US',
    timezone TEXT DEFAULT 'America/New_York',
    
    -- Platform Preferences
    preferred_language TEXT DEFAULT 'en',
    email_notifications BOOLEAN DEFAULT true,
    weekly_digest BOOLEAN DEFAULT true,
    
    -- Profile Status
    onboarding_completed BOOLEAN DEFAULT false,
    profile_complete BOOLEAN DEFAULT false,
    last_active_at TIMESTAMP WITH TIME ZONE,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Teams table (can have multiple mentors)
CREATE TABLE IF NOT EXISTS teams (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    team_name TEXT NOT NULL,
    team_number INTEGER UNIQUE, -- Official FLL team number
    organization TEXT,
    student_count INTEGER CHECK (student_count > 0),
    age_group TEXT CHECK (age_group IN ('explore', 'challenge', 'discover')),
    
    -- Team Settings
    meeting_frequency TEXT CHECK (meeting_frequency IN ('weekly', 'bi-weekly', 'custom')) DEFAULT 'weekly',
    meeting_day TEXT, -- Monday, Tuesday, etc
    meeting_time TIME,
    meeting_duration INTEGER DEFAULT 120, -- minutes
    meeting_location TEXT,
    
    -- Communication Settings
    parent_email_enabled BOOLEAN DEFAULT true,
    weekly_updates BOOLEAN DEFAULT true,
    reminder_notifications BOOLEAN DEFAULT true,
    
    -- Competition Info
    competition_date DATE,
    competition_location TEXT,
    competition_level TEXT, -- regional, state, world
    
    -- Status
    active BOOLEAN DEFAULT true,
    current_season TEXT DEFAULT '2024-2025',
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Junction table: Mentors ↔ Teams with roles and permissions
CREATE TABLE IF NOT EXISTS team_mentors (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    team_id UUID NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
    mentor_id UUID NOT NULL REFERENCES mentors(id) ON DELETE CASCADE,
    
    -- Role & Status
    role TEXT NOT NULL CHECK (role IN ('head_mentor', 'assistant_mentor', 'technical_advisor', 'guest')) DEFAULT 'assistant_mentor',
    status TEXT DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'pending_invitation')),
    
    -- Permissions (can be customized per mentor)
    can_invite_mentors BOOLEAN DEFAULT false,
    can_edit_plans BOOLEAN DEFAULT true,
    can_send_emails BOOLEAN DEFAULT false,
    can_manage_settings BOOLEAN DEFAULT false,
    
    -- Metadata
    invited_by_mentor_id UUID REFERENCES mentors(id),
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    invited_at TIMESTAMP WITH TIME ZONE,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(team_id, mentor_id)
);

-- Team Invitations (for inviting mentors to teams)
CREATE TABLE IF NOT EXISTS team_invitations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    team_id UUID NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
    invited_by_mentor_id UUID NOT NULL REFERENCES mentors(id),
    
    -- Invitation Details
    email TEXT NOT NULL,
    proposed_role TEXT CHECK (proposed_role IN ('assistant_mentor', 'technical_advisor', 'guest')) DEFAULT 'assistant_mentor',
    invitation_token UUID DEFAULT uuid_generate_v4(),
    personal_message TEXT,
    
    -- Permissions for invited role
    can_invite_mentors BOOLEAN DEFAULT false,
    can_edit_plans BOOLEAN DEFAULT true,
    can_send_emails BOOLEAN DEFAULT false,
    can_manage_settings BOOLEAN DEFAULT false,
    
    -- Status
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'rejected', 'expired')),
    expires_at TIMESTAMP WITH TIME ZONE DEFAULT (NOW() + INTERVAL '7 days'),
    accepted_at TIMESTAMP WITH TIME ZONE,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Mentor Activity Log (track platform usage)
CREATE TABLE IF NOT EXISTS mentor_activity_log (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    mentor_id UUID NOT NULL REFERENCES mentors(id) ON DELETE CASCADE,
    
    -- Activity Details
    action TEXT NOT NULL, -- login, create_plan, generate_agenda, etc.
    resource_type TEXT, -- season_plan, agenda, email, team, etc.
    resource_id UUID, -- ID of the resource acted upon
    team_id UUID REFERENCES teams(id), -- Context: which team
    
    -- Session Context
    session_id TEXT, -- Group actions in same session
    ip_address INET,
    user_agent TEXT,
    
    -- Metadata
    metadata JSONB DEFAULT '{}', -- Flexible data for specific actions
    duration_seconds INTEGER, -- Time spent on action
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_mentors_clerk_user_id ON mentors(clerk_user_id);
CREATE INDEX IF NOT EXISTS idx_mentors_email ON mentors(email);
CREATE INDEX IF NOT EXISTS idx_teams_team_number ON teams(team_number);
CREATE INDEX IF NOT EXISTS idx_teams_current_season ON teams(current_season);
CREATE INDEX IF NOT EXISTS idx_team_mentors_team_id ON team_mentors(team_id);
CREATE INDEX IF NOT EXISTS idx_team_mentors_mentor_id ON team_mentors(mentor_id);
CREATE INDEX IF NOT EXISTS idx_team_mentors_role ON team_mentors(role);
CREATE INDEX IF NOT EXISTS idx_team_invitations_email ON team_invitations(email);
CREATE INDEX IF NOT EXISTS idx_team_invitations_token ON team_invitations(invitation_token);
CREATE INDEX IF NOT EXISTS idx_mentor_activity_mentor_id ON mentor_activity_log(mentor_id);
CREATE INDEX IF NOT EXISTS idx_mentor_activity_team_id ON mentor_activity_log(team_id);
CREATE INDEX IF NOT EXISTS idx_mentor_activity_action ON mentor_activity_log(action);

-- Create triggers for updated_at timestamps
CREATE TRIGGER update_mentors_updated_at 
    BEFORE UPDATE ON mentors 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_teams_updated_at 
    BEFORE UPDATE ON teams 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_team_mentors_updated_at 
    BEFORE UPDATE ON team_mentors 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_team_invitations_updated_at 
    BEFORE UPDATE ON team_invitations 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- Function to set default permissions based on role
CREATE OR REPLACE FUNCTION set_mentor_permissions()
RETURNS TRIGGER AS $$
BEGIN
    -- Set permissions based on role
    CASE NEW.role
        WHEN 'head_mentor' THEN
            NEW.can_invite_mentors := true;
            NEW.can_edit_plans := true;
            NEW.can_send_emails := true;
            NEW.can_manage_settings := true;
        WHEN 'assistant_mentor' THEN
            NEW.can_invite_mentors := COALESCE(NEW.can_invite_mentors, false);
            NEW.can_edit_plans := true;
            NEW.can_send_emails := COALESCE(NEW.can_send_emails, false);
            NEW.can_manage_settings := false;
        WHEN 'technical_advisor' THEN
            NEW.can_invite_mentors := false;
            NEW.can_edit_plans := true;
            NEW.can_send_emails := false;
            NEW.can_manage_settings := false;
        WHEN 'guest' THEN
            NEW.can_invite_mentors := false;
            NEW.can_edit_plans := false;
            NEW.can_send_emails := false;
            NEW.can_manage_settings := false;
    END CASE;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to auto-set permissions when role changes
CREATE TRIGGER set_team_mentor_permissions
    BEFORE INSERT OR UPDATE OF role ON team_mentors
    FOR EACH ROW
    EXECUTE FUNCTION set_mentor_permissions();

-- Function to handle head mentor succession when head mentor leaves
CREATE OR REPLACE FUNCTION handle_head_mentor_departure()
RETURNS TRIGGER AS $$
DECLARE
    new_head_mentor_id UUID;
    team_id_var UUID;
BEGIN
    -- Only proceed if we're removing a head mentor
    IF OLD.role = 'head_mentor' AND (TG_OP = 'DELETE' OR NEW.status = 'inactive') THEN
        team_id_var := OLD.team_id;
        
        -- Find the most senior assistant mentor to promote
        SELECT mentor_id INTO new_head_mentor_id
        FROM team_mentors 
        WHERE team_id = team_id_var
            AND mentor_id != OLD.mentor_id
            AND role IN ('assistant_mentor', 'technical_advisor')
            AND status = 'active'
        ORDER BY joined_at ASC
        LIMIT 1;
        
        -- Promote to head mentor if found
        IF new_head_mentor_id IS NOT NULL THEN
            UPDATE team_mentors 
            SET role = 'head_mentor'
            WHERE team_id = team_id_var AND mentor_id = new_head_mentor_id;
            
            -- Log the succession
            INSERT INTO mentor_activity_log (mentor_id, action, resource_type, resource_id, team_id, metadata)
            VALUES (
                new_head_mentor_id, 
                'promoted_to_head_mentor', 
                'team', 
                team_id_var, 
                team_id_var,
                json_build_object('previous_head_mentor_id', OLD.mentor_id, 'succession_reason', 'head_mentor_departure')
            );
        END IF;
    END IF;
    
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

-- Trigger for head mentor succession
CREATE TRIGGER handle_head_mentor_succession
    AFTER UPDATE OF status OR DELETE ON team_mentors
    FOR EACH ROW
    EXECUTE FUNCTION handle_head_mentor_departure();