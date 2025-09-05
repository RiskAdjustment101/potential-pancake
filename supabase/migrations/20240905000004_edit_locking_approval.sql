-- Migration: 20240905000004_edit_locking_approval
-- Adds edit locking, approval workflow, and plan versioning

-- Plan Approval System
CREATE TABLE IF NOT EXISTS plan_approvals (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    season_plan_id UUID NOT NULL REFERENCES season_plans(id) ON DELETE CASCADE,
    mentor_id UUID NOT NULL REFERENCES mentors(id) ON DELETE CASCADE,
    
    -- Approval Details
    status TEXT CHECK (status IN ('pending', 'approved', 'rejected', 'commented')) DEFAULT 'pending',
    feedback TEXT,
    approved_at TIMESTAMP WITH TIME ZONE,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(season_plan_id, mentor_id)
);

-- Plan Edit History (track changes for conflict resolution)
CREATE TABLE IF NOT EXISTS plan_edit_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    season_plan_id UUID NOT NULL REFERENCES season_plans(id) ON DELETE CASCADE,
    edited_by_mentor_id UUID NOT NULL REFERENCES mentors(id),
    
    -- Change Details
    changes_made JSONB DEFAULT '{}', -- What was changed
    version_number INTEGER NOT NULL,
    edit_summary TEXT,
    plan_snapshot JSONB, -- Full plan state at this version
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add edit locking and approval columns to existing season_plans
ALTER TABLE season_plans ADD COLUMN IF NOT EXISTS mentor_id UUID REFERENCES mentors(id);
ALTER TABLE season_plans ADD COLUMN IF NOT EXISTS team_id UUID REFERENCES teams(id);
ALTER TABLE season_plans ADD COLUMN IF NOT EXISTS created_by_mentor_id UUID REFERENCES mentors(id);

-- Edit Control columns
ALTER TABLE season_plans ADD COLUMN IF NOT EXISTS currently_editing_mentor_id UUID REFERENCES mentors(id);
ALTER TABLE season_plans ADD COLUMN IF NOT EXISTS locked_at TIMESTAMP WITH TIME ZONE;
ALTER TABLE season_plans ADD COLUMN IF NOT EXISTS lock_expires_at TIMESTAMP WITH TIME ZONE;

-- Approval System columns
ALTER TABLE season_plans ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'draft' CHECK (status IN ('draft', 'pending_approval', 'approved', 'archived'));
ALTER TABLE season_plans ADD COLUMN IF NOT EXISTS requires_approval BOOLEAN DEFAULT false;
ALTER TABLE season_plans ADD COLUMN IF NOT EXISTS version_number INTEGER DEFAULT 1;

-- Add plan name and season year if not exists
ALTER TABLE season_plans ADD COLUMN IF NOT EXISTS plan_name TEXT DEFAULT 'Season Plan';
ALTER TABLE season_plans ADD COLUMN IF NOT EXISTS season_year TEXT DEFAULT '2024-2025';

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_season_plans_mentor_id ON season_plans(mentor_id);
CREATE INDEX IF NOT EXISTS idx_season_plans_team_id ON season_plans(team_id);
CREATE INDEX IF NOT EXISTS idx_season_plans_status ON season_plans(status);
CREATE INDEX IF NOT EXISTS idx_season_plans_currently_editing ON season_plans(currently_editing_mentor_id);
CREATE INDEX IF NOT EXISTS idx_plan_approvals_season_plan_id ON plan_approvals(season_plan_id);
CREATE INDEX IF NOT EXISTS idx_plan_approvals_mentor_id ON plan_approvals(mentor_id);
CREATE INDEX IF NOT EXISTS idx_plan_edit_history_season_plan_id ON plan_edit_history(season_plan_id);

-- Create trigger for plan approval updated_at
CREATE TRIGGER update_plan_approvals_updated_at 
    BEFORE UPDATE ON plan_approvals 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- Function to acquire edit lock
CREATE OR REPLACE FUNCTION acquire_plan_lock(plan_id UUID, mentor_id UUID)
RETURNS JSONB AS $$
DECLARE
    lock_acquired BOOLEAN := false;
    current_editor UUID;
    lock_expiry TIMESTAMP WITH TIME ZONE;
    result JSONB;
BEGIN
    -- Check current lock status
    SELECT currently_editing_mentor_id, lock_expires_at 
    INTO current_editor, lock_expiry
    FROM season_plans 
    WHERE id = plan_id;
    
    -- Try to acquire lock
    UPDATE season_plans 
    SET 
        currently_editing_mentor_id = mentor_id,
        locked_at = NOW(),
        lock_expires_at = NOW() + INTERVAL '30 minutes'
    WHERE 
        id = plan_id 
        AND (
            currently_editing_mentor_id IS NULL 
            OR lock_expires_at < NOW()
            OR currently_editing_mentor_id = mentor_id
        );
        
    GET DIAGNOSTICS lock_acquired = ROW_COUNT > 0;
    
    -- Return result
    IF lock_acquired THEN
        result := jsonb_build_object(
            'success', true,
            'locked_by', mentor_id,
            'expires_at', NOW() + INTERVAL '30 minutes',
            'message', 'Lock acquired successfully'
        );
    ELSE
        result := jsonb_build_object(
            'success', false,
            'locked_by', current_editor,
            'expires_at', lock_expiry,
            'message', 'Plan is currently being edited by another mentor'
        );
    END IF;
    
    RETURN result;
END;
$$ LANGUAGE plpgsql;

-- Function to release edit lock
CREATE OR REPLACE FUNCTION release_plan_lock(plan_id UUID, mentor_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
    lock_released BOOLEAN := false;
BEGIN
    UPDATE season_plans 
    SET 
        currently_editing_mentor_id = NULL,
        locked_at = NULL,
        lock_expires_at = NULL
    WHERE 
        id = plan_id 
        AND currently_editing_mentor_id = mentor_id;
        
    GET DIAGNOSTICS lock_released = ROW_COUNT > 0;
    RETURN lock_released;
END;
$$ LANGUAGE plpgsql;

-- Function to extend edit lock
CREATE OR REPLACE FUNCTION extend_plan_lock(plan_id UUID, mentor_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
    lock_extended BOOLEAN := false;
BEGIN
    UPDATE season_plans 
    SET 
        lock_expires_at = NOW() + INTERVAL '30 minutes'
    WHERE 
        id = plan_id 
        AND currently_editing_mentor_id = mentor_id
        AND lock_expires_at > NOW(); -- Only extend if still valid
        
    GET DIAGNOSTICS lock_extended = ROW_COUNT > 0;
    RETURN lock_extended;
END;
$$ LANGUAGE plpgsql;

-- Function to save plan changes and handle approval workflow
CREATE OR REPLACE FUNCTION save_plan_with_approval_check(
    plan_id UUID, 
    mentor_id UUID, 
    changes JSONB, 
    edit_summary TEXT DEFAULT NULL
)
RETURNS JSONB AS $$
DECLARE
    plan_record RECORD;
    team_mentor_count INTEGER;
    requires_approval_flag BOOLEAN := false;
    new_version INTEGER;
    result JSONB;
BEGIN
    -- Get current plan info
    SELECT * INTO plan_record 
    FROM season_plans 
    WHERE id = plan_id;
    
    -- Check if mentor has permission to edit
    IF plan_record.currently_editing_mentor_id IS NULL OR plan_record.currently_editing_mentor_id != mentor_id THEN
        RETURN jsonb_build_object('success', false, 'message', 'No edit lock held by this mentor');
    END IF;
    
    -- Count team mentors to determine if approval is needed
    SELECT COUNT(*) INTO team_mentor_count
    FROM team_mentors 
    WHERE team_id = plan_record.team_id 
        AND status = 'active' 
        AND can_edit_plans = true;
    
    -- Require approval if multiple mentors can edit
    requires_approval_flag := (team_mentor_count > 1);
    
    -- Increment version
    new_version := plan_record.version_number + 1;
    
    -- Update plan with changes
    UPDATE season_plans 
    SET 
        version_number = new_version,
        requires_approval = requires_approval_flag,
        status = CASE 
            WHEN requires_approval_flag THEN 'pending_approval'
            ELSE 'approved'
        END,
        updated_at = NOW(),
        -- Release lock
        currently_editing_mentor_id = NULL,
        locked_at = NULL,
        lock_expires_at = NULL
    WHERE id = plan_id;
    
    -- Create edit history record
    INSERT INTO plan_edit_history (
        season_plan_id, 
        edited_by_mentor_id, 
        changes_made, 
        version_number, 
        edit_summary,
        plan_snapshot
    ) VALUES (
        plan_id, 
        mentor_id, 
        changes, 
        new_version, 
        edit_summary,
        to_jsonb(plan_record)
    );
    
    -- If approval required, create approval records for all team mentors
    IF requires_approval_flag THEN
        INSERT INTO plan_approvals (season_plan_id, mentor_id, status)
        SELECT plan_id, tm.mentor_id, 'pending'
        FROM team_mentors tm
        WHERE tm.team_id = plan_record.team_id 
            AND tm.status = 'active' 
            AND tm.can_edit_plans = true
            AND tm.mentor_id != mentor_id -- Don't require self-approval
        ON CONFLICT (season_plan_id, mentor_id) 
        DO UPDATE SET status = 'pending', created_at = NOW();
    END IF;
    
    -- Log the activity
    INSERT INTO mentor_activity_log (mentor_id, action, resource_type, resource_id, team_id, metadata)
    VALUES (
        mentor_id,
        'save_plan',
        'season_plan',
        plan_id,
        plan_record.team_id,
        jsonb_build_object(
            'version', new_version,
            'requires_approval', requires_approval_flag,
            'changes_summary', edit_summary
        )
    );
    
    result := jsonb_build_object(
        'success', true,
        'version', new_version,
        'requires_approval', requires_approval_flag,
        'status', CASE WHEN requires_approval_flag THEN 'pending_approval' ELSE 'approved' END
    );
    
    RETURN result;
END;
$$ LANGUAGE plpgsql;

-- Function to approve/reject plan
CREATE OR REPLACE FUNCTION submit_plan_approval(
    plan_id UUID,
    mentor_id UUID,
    approval_status TEXT, -- 'approved', 'rejected', 'commented'
    feedback_text TEXT DEFAULT NULL
)
RETURNS JSONB AS $$
DECLARE
    approval_count INTEGER;
    total_approvers INTEGER;
    plan_team_id UUID;
BEGIN
    -- Update the approval record
    UPDATE plan_approvals 
    SET 
        status = approval_status,
        feedback = feedback_text,
        approved_at = CASE WHEN approval_status = 'approved' THEN NOW() ELSE approved_at END,
        updated_at = NOW()
    WHERE season_plan_id = plan_id AND mentor_id = mentor_id;
    
    -- Get team info
    SELECT team_id INTO plan_team_id FROM season_plans WHERE id = plan_id;
    
    -- Count approvals
    SELECT 
        COUNT(*) FILTER (WHERE status = 'approved'),
        COUNT(*)
    INTO approval_count, total_approvers
    FROM plan_approvals 
    WHERE season_plan_id = plan_id;
    
    -- If all mentors approved, mark plan as approved
    IF approval_count = total_approvers THEN
        UPDATE season_plans 
        SET status = 'approved', requires_approval = false
        WHERE id = plan_id;
        
        -- Log the approval
        INSERT INTO mentor_activity_log (mentor_id, action, resource_type, resource_id, team_id, metadata)
        VALUES (
            mentor_id,
            'plan_fully_approved',
            'season_plan',
            plan_id,
            plan_team_id,
            jsonb_build_object('total_approvers', total_approvers)
        );
        
        RETURN jsonb_build_object('success', true, 'plan_status', 'approved', 'message', 'Plan fully approved');
    ELSE
        RETURN jsonb_build_object('success', true, 'plan_status', 'pending_approval', 'approvals', approval_count, 'total', total_approvers);
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Function to clean up expired locks (run via cron)
CREATE OR REPLACE FUNCTION cleanup_expired_locks()
RETURNS INTEGER AS $$
DECLARE
    cleaned_count INTEGER;
BEGIN
    UPDATE season_plans 
    SET 
        currently_editing_mentor_id = NULL,
        locked_at = NULL,
        lock_expires_at = NULL
    WHERE 
        lock_expires_at IS NOT NULL 
        AND lock_expires_at < NOW();
        
    GET DIAGNOSTICS cleaned_count = ROW_COUNT;
    RETURN cleaned_count;
END;
$$ LANGUAGE plpgsql;