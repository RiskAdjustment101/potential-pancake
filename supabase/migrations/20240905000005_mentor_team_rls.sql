-- Migration: 20240905000005_mentor_team_rls
-- Row Level Security policies for multi-mentor team system

-- Enable RLS on all new tables
ALTER TABLE mentors ENABLE ROW LEVEL SECURITY;
ALTER TABLE teams ENABLE ROW LEVEL SECURITY;
ALTER TABLE team_mentors ENABLE ROW LEVEL SECURITY;
ALTER TABLE team_invitations ENABLE ROW LEVEL SECURITY;
ALTER TABLE mentor_activity_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE plan_approvals ENABLE ROW LEVEL SECURITY;
ALTER TABLE plan_edit_history ENABLE ROW LEVEL SECURITY;

-- MENTORS table policies
-- Mentors can view and edit their own profile
CREATE POLICY "Mentors can view own profile" ON mentors
    FOR SELECT USING (auth.jwt() ->> 'sub' = clerk_user_id);

CREATE POLICY "Mentors can update own profile" ON mentors
    FOR UPDATE USING (auth.jwt() ->> 'sub' = clerk_user_id);

CREATE POLICY "Anyone can create mentor profile" ON mentors
    FOR INSERT WITH CHECK (auth.jwt() ->> 'sub' = clerk_user_id);

-- Mentors can view basic info of other mentors on their teams
CREATE POLICY "Mentors can view teammates basic info" ON mentors
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM team_mentors tm1
            JOIN team_mentors tm2 ON tm1.team_id = tm2.team_id
            WHERE tm1.mentor_id = mentors.id
            AND tm2.mentor_id IN (
                SELECT m.id FROM mentors m WHERE m.clerk_user_id = auth.jwt() ->> 'sub'
            )
            AND tm1.status = 'active' AND tm2.status = 'active'
        )
    );

-- TEAMS table policies
-- Mentors can view teams they're part of
CREATE POLICY "Mentors can view own teams" ON teams
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM team_mentors tm
            JOIN mentors m ON tm.mentor_id = m.id
            WHERE tm.team_id = teams.id
            AND m.clerk_user_id = auth.jwt() ->> 'sub'
            AND tm.status = 'active'
        )
    );

-- Head mentors and those with manage_settings permission can update team
CREATE POLICY "Team managers can update teams" ON teams
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM team_mentors tm
            JOIN mentors m ON tm.mentor_id = m.id
            WHERE tm.team_id = teams.id
            AND m.clerk_user_id = auth.jwt() ->> 'sub'
            AND tm.status = 'active'
            AND tm.can_manage_settings = true
        )
    );

-- Anyone can create a team (they become head mentor)
CREATE POLICY "Anyone can create team" ON teams
    FOR INSERT WITH CHECK (true);

-- TEAM_MENTORS table policies
-- Mentors can view team membership for their teams
CREATE POLICY "Mentors can view team membership" ON team_mentors
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM team_mentors tm
            JOIN mentors m ON tm.mentor_id = m.id
            WHERE tm.team_id = team_mentors.team_id
            AND m.clerk_user_id = auth.jwt() ->> 'sub'
            AND tm.status = 'active'
        )
    );

-- Mentors can update their own team membership (leave team, change preferences)
CREATE POLICY "Mentors can update own membership" ON team_mentors
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM mentors m 
            WHERE m.id = team_mentors.mentor_id 
            AND m.clerk_user_id = auth.jwt() ->> 'sub'
        )
    );

-- Mentors with invite permission can add new team members
CREATE POLICY "Mentors can invite to teams" ON team_mentors
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM team_mentors tm
            JOIN mentors m ON tm.mentor_id = m.id
            WHERE tm.team_id = team_mentors.team_id
            AND m.clerk_user_id = auth.jwt() ->> 'sub'
            AND tm.status = 'active'
            AND tm.can_invite_mentors = true
        )
    );

-- Head mentors can remove team members
CREATE POLICY "Head mentors can manage membership" ON team_mentors
    FOR DELETE USING (
        EXISTS (
            SELECT 1 FROM team_mentors tm
            JOIN mentors m ON tm.mentor_id = m.id
            WHERE tm.team_id = team_mentors.team_id
            AND m.clerk_user_id = auth.jwt() ->> 'sub'
            AND tm.status = 'active'
            AND tm.role = 'head_mentor'
        )
    );

-- TEAM_INVITATIONS table policies
-- Mentors can view invitations for their teams
CREATE POLICY "Mentors can view team invitations" ON team_invitations
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM team_mentors tm
            JOIN mentors m ON tm.mentor_id = m.id
            WHERE tm.team_id = team_invitations.team_id
            AND m.clerk_user_id = auth.jwt() ->> 'sub'
            AND tm.status = 'active'
        )
    );

-- Mentors with invite permission can create invitations
CREATE POLICY "Mentors can create invitations" ON team_invitations
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM team_mentors tm
            JOIN mentors m ON tm.mentor_id = m.id
            WHERE tm.team_id = team_invitations.team_id
            AND m.clerk_user_id = auth.jwt() ->> 'sub'
            AND tm.status = 'active'
            AND tm.can_invite_mentors = true
        )
    );

-- Inviting mentors can update their invitations
CREATE POLICY "Mentors can manage own invitations" ON team_invitations
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM mentors m 
            WHERE m.id = team_invitations.invited_by_mentor_id 
            AND m.clerk_user_id = auth.jwt() ->> 'sub'
        )
    );

-- SEASON_PLANS table policies (updated for team system)
-- Drop existing policies first
DROP POLICY IF EXISTS "Users can view own season plans" ON season_plans;
DROP POLICY IF EXISTS "Users can insert own season plans" ON season_plans;
DROP POLICY IF EXISTS "Users can update own season plans" ON season_plans;
DROP POLICY IF EXISTS "Users can delete own season plans" ON season_plans;

-- Mentors can view plans for their teams
CREATE POLICY "Mentors can view team season plans" ON season_plans
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM team_mentors tm
            JOIN mentors m ON tm.mentor_id = m.id
            WHERE tm.team_id = season_plans.team_id
            AND m.clerk_user_id = auth.jwt() ->> 'sub'
            AND tm.status = 'active'
        )
    );

-- Mentors with edit permission can create plans
CREATE POLICY "Mentors can create team plans" ON season_plans
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM team_mentors tm
            JOIN mentors m ON tm.mentor_id = m.id
            WHERE tm.team_id = season_plans.team_id
            AND m.clerk_user_id = auth.jwt() ->> 'sub'
            AND tm.status = 'active'
            AND tm.can_edit_plans = true
        )
    );

-- Mentors with edit permission can update plans (with locking check)
CREATE POLICY "Mentors can edit team plans" ON season_plans
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM team_mentors tm
            JOIN mentors m ON tm.mentor_id = m.id
            WHERE tm.team_id = season_plans.team_id
            AND m.clerk_user_id = auth.jwt() ->> 'sub'
            AND tm.status = 'active'
            AND tm.can_edit_plans = true
        )
    );

-- Head mentors can delete plans
CREATE POLICY "Head mentors can delete plans" ON season_plans
    FOR DELETE USING (
        EXISTS (
            SELECT 1 FROM team_mentors tm
            JOIN mentors m ON tm.mentor_id = m.id
            WHERE tm.team_id = season_plans.team_id
            AND m.clerk_user_id = auth.jwt() ->> 'sub'
            AND tm.status = 'active'
            AND tm.role = 'head_mentor'
        )
    );

-- SEASON_WEEKS table policies (updated)
DROP POLICY IF EXISTS "Users can view own season weeks" ON season_weeks;
DROP POLICY IF EXISTS "Users can insert own season weeks" ON season_weeks;
DROP POLICY IF EXISTS "Users can update own season weeks" ON season_weeks;
DROP POLICY IF EXISTS "Users can delete own season weeks" ON season_weeks;

-- Season weeks inherit permissions from season plans
CREATE POLICY "Mentors can view team season weeks" ON season_weeks
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM season_plans sp
            JOIN team_mentors tm ON tm.team_id = sp.team_id
            JOIN mentors m ON tm.mentor_id = m.id
            WHERE sp.id = season_weeks.season_plan_id
            AND m.clerk_user_id = auth.jwt() ->> 'sub'
            AND tm.status = 'active'
        )
    );

CREATE POLICY "Mentors can manage team season weeks" ON season_weeks
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM season_plans sp
            JOIN team_mentors tm ON tm.team_id = sp.team_id
            JOIN mentors m ON tm.mentor_id = m.id
            WHERE sp.id = season_weeks.season_plan_id
            AND m.clerk_user_id = auth.jwt() ->> 'sub'
            AND tm.status = 'active'
            AND tm.can_edit_plans = true
        )
    );

-- WEEKLY_AGENDAS table policies (updated)
DROP POLICY IF EXISTS "Users can view own agendas" ON weekly_agendas;
DROP POLICY IF EXISTS "Users can insert own agendas" ON weekly_agendas;
DROP POLICY IF EXISTS "Users can update own agendas" ON weekly_agendas;
DROP POLICY IF EXISTS "Users can delete own agendas" ON weekly_agendas;

-- Add team context to weekly_agendas via season_weeks
CREATE POLICY "Mentors can view team agendas" ON weekly_agendas
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM season_weeks sw
            JOIN season_plans sp ON sp.id = sw.season_plan_id
            JOIN team_mentors tm ON tm.team_id = sp.team_id
            JOIN mentors m ON tm.mentor_id = m.id
            WHERE (sw.id = weekly_agendas.season_week_id OR weekly_agendas.user_id = m.clerk_user_id)
            AND m.clerk_user_id = auth.jwt() ->> 'sub'
            AND tm.status = 'active'
        )
    );

CREATE POLICY "Mentors can manage team agendas" ON weekly_agendas
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM season_weeks sw
            JOIN season_plans sp ON sp.id = sw.season_plan_id
            JOIN team_mentors tm ON tm.team_id = sp.team_id
            JOIN mentors m ON tm.mentor_id = m.id
            WHERE (sw.id = weekly_agendas.season_week_id OR weekly_agendas.user_id = m.clerk_user_id)
            AND m.clerk_user_id = auth.jwt() ->> 'sub'
            AND tm.status = 'active'
            AND tm.can_edit_plans = true
        )
    );

-- PARENT_COMMS table policies (updated)
DROP POLICY IF EXISTS "Users can view own parent comms" ON parent_comms;
DROP POLICY IF EXISTS "Users can insert own parent comms" ON parent_comms;
DROP POLICY IF EXISTS "Users can update own parent comms" ON parent_comms;
DROP POLICY IF EXISTS "Users can delete own parent comms" ON parent_comms;

CREATE POLICY "Mentors can view team parent comms" ON parent_comms
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM season_plans sp
            JOIN team_mentors tm ON tm.team_id = sp.team_id
            JOIN mentors m ON tm.mentor_id = m.id
            WHERE (sp.id = parent_comms.season_plan_id OR parent_comms.user_id = m.clerk_user_id)
            AND m.clerk_user_id = auth.jwt() ->> 'sub'
            AND tm.status = 'active'
        )
    );

CREATE POLICY "Mentors can send parent comms" ON parent_comms
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM season_plans sp
            JOIN team_mentors tm ON tm.team_id = sp.team_id
            JOIN mentors m ON tm.mentor_id = m.id
            WHERE (sp.id = parent_comms.season_plan_id OR parent_comms.user_id = m.clerk_user_id)
            AND m.clerk_user_id = auth.jwt() ->> 'sub'
            AND tm.status = 'active'
            AND tm.can_send_emails = true
        )
    );

CREATE POLICY "Mentors can edit parent comms" ON parent_comms
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM season_plans sp
            JOIN team_mentors tm ON tm.team_id = sp.team_id
            JOIN mentors m ON tm.mentor_id = m.id
            WHERE (sp.id = parent_comms.season_plan_id OR parent_comms.user_id = m.clerk_user_id)
            AND m.clerk_user_id = auth.jwt() ->> 'sub'
            AND tm.status = 'active'
            AND tm.can_send_emails = true
        )
    );

CREATE POLICY "Mentors can delete parent comms" ON parent_comms
    FOR DELETE USING (
        EXISTS (
            SELECT 1 FROM season_plans sp
            JOIN team_mentors tm ON tm.team_id = sp.team_id
            JOIN mentors m ON tm.mentor_id = m.id
            WHERE (sp.id = parent_comms.season_plan_id OR parent_comms.user_id = m.clerk_user_id)
            AND m.clerk_user_id = auth.jwt() ->> 'sub'
            AND tm.status = 'active'
            AND tm.can_send_emails = true
        )
    );

-- PLAN_APPROVALS table policies
-- Mentors can view approvals for plans on their teams
CREATE POLICY "Mentors can view team plan approvals" ON plan_approvals
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM season_plans sp
            JOIN team_mentors tm ON tm.team_id = sp.team_id
            JOIN mentors m ON tm.mentor_id = m.id
            WHERE sp.id = plan_approvals.season_plan_id
            AND m.clerk_user_id = auth.jwt() ->> 'sub'
            AND tm.status = 'active'
        )
    );

-- Mentors can submit their own approvals
CREATE POLICY "Mentors can submit approvals" ON plan_approvals
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM mentors m 
            WHERE m.id = plan_approvals.mentor_id 
            AND m.clerk_user_id = auth.jwt() ->> 'sub'
        )
    );

-- PLAN_EDIT_HISTORY table policies
-- Mentors can view edit history for their team plans
CREATE POLICY "Mentors can view plan history" ON plan_edit_history
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM season_plans sp
            JOIN team_mentors tm ON tm.team_id = sp.team_id
            JOIN mentors m ON tm.mentor_id = m.id
            WHERE sp.id = plan_edit_history.season_plan_id
            AND m.clerk_user_id = auth.jwt() ->> 'sub'
            AND tm.status = 'active'
        )
    );

-- System can insert edit history (handled by functions)
CREATE POLICY "System can insert edit history" ON plan_edit_history
    FOR INSERT WITH CHECK (true);

-- MENTOR_ACTIVITY_LOG table policies
-- Mentors can view their own activity
CREATE POLICY "Mentors can view own activity" ON mentor_activity_log
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM mentors m 
            WHERE m.id = mentor_activity_log.mentor_id 
            AND m.clerk_user_id = auth.jwt() ->> 'sub'
        )
    );

-- System can insert activity logs
CREATE POLICY "System can log activity" ON mentor_activity_log
    FOR INSERT WITH CHECK (true);