-- Migration: 20240905000006_fix_function_security
-- Fixes security warnings by adding search_path to all functions

-- Drop and recreate update_updated_at_column with security settings
DROP FUNCTION IF EXISTS update_updated_at_column() CASCADE;
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER 
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Recreate triggers that were dropped
CREATE TRIGGER update_season_plans_updated_at 
    BEFORE UPDATE ON season_plans 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_season_weeks_updated_at 
    BEFORE UPDATE ON season_weeks 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_weekly_agendas_updated_at 
    BEFORE UPDATE ON weekly_agendas 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_parent_comms_updated_at 
    BEFORE UPDATE ON parent_comms 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

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

CREATE TRIGGER update_plan_approvals_updated_at 
    BEFORE UPDATE ON plan_approvals 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- Fix set_mentor_permissions function
DROP FUNCTION IF EXISTS set_mentor_permissions() CASCADE;
CREATE OR REPLACE FUNCTION set_mentor_permissions()
RETURNS TRIGGER 
SECURITY DEFINER
SET search_path = public
AS $$
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

-- Recreate trigger
CREATE TRIGGER set_team_mentor_permissions
    BEFORE INSERT OR UPDATE OF role ON team_mentors
    FOR EACH ROW
    EXECUTE FUNCTION set_mentor_permissions();

-- Fix handle_head_mentor_departure function
DROP FUNCTION IF EXISTS handle_head_mentor_departure() CASCADE;
CREATE OR REPLACE FUNCTION handle_head_mentor_departure()
RETURNS TRIGGER 
SECURITY DEFINER
SET search_path = public
AS $$
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

-- Recreate trigger
CREATE TRIGGER handle_head_mentor_succession
    AFTER UPDATE OF status OR DELETE ON team_mentors
    FOR EACH ROW
    EXECUTE FUNCTION handle_head_mentor_departure();

-- Fix acquire_plan_lock function
DROP FUNCTION IF EXISTS acquire_plan_lock(UUID, UUID);
CREATE OR REPLACE FUNCTION acquire_plan_lock(plan_id UUID, mentor_id UUID)
RETURNS JSONB 
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    lock_acquired BOOLEAN := false;
    current_editor UUID;
    lock_expiry TIMESTAMP WITH TIME ZONE;
    result JSONB;
    rows_updated INTEGER;
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
        
    GET DIAGNOSTICS rows_updated = ROW_COUNT;
    lock_acquired := rows_updated > 0;
    
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

-- Fix release_plan_lock function
DROP FUNCTION IF EXISTS release_plan_lock(UUID, UUID);
CREATE OR REPLACE FUNCTION release_plan_lock(plan_id UUID, mentor_id UUID)
RETURNS BOOLEAN 
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    lock_released BOOLEAN := false;
    rows_updated INTEGER;
BEGIN
    UPDATE season_plans 
    SET 
        currently_editing_mentor_id = NULL,
        locked_at = NULL,
        lock_expires_at = NULL
    WHERE 
        id = plan_id 
        AND currently_editing_mentor_id = mentor_id;
        
    GET DIAGNOSTICS rows_updated = ROW_COUNT;
    lock_released := rows_updated > 0;
    RETURN lock_released;
END;
$$ LANGUAGE plpgsql;

-- Fix extend_plan_lock function
DROP FUNCTION IF EXISTS extend_plan_lock(UUID, UUID);
CREATE OR REPLACE FUNCTION extend_plan_lock(plan_id UUID, mentor_id UUID)
RETURNS BOOLEAN 
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    lock_extended BOOLEAN := false;
    rows_updated INTEGER;
BEGIN
    UPDATE season_plans 
    SET 
        lock_expires_at = NOW() + INTERVAL '30 minutes'
    WHERE 
        id = plan_id 
        AND currently_editing_mentor_id = mentor_id
        AND lock_expires_at > NOW(); -- Only extend if still valid
        
    GET DIAGNOSTICS rows_updated = ROW_COUNT;
    lock_extended := rows_updated > 0;
    RETURN lock_extended;
END;
$$ LANGUAGE plpgsql;

-- Fix save_plan_with_approval_check function
DROP FUNCTION IF EXISTS save_plan_with_approval_check(UUID, UUID, JSONB, TEXT);
CREATE OR REPLACE FUNCTION save_plan_with_approval_check(
    plan_id UUID, 
    mentor_id UUID, 
    changes JSONB, 
    edit_summary TEXT DEFAULT NULL
)
RETURNS JSONB 
SECURITY DEFINER
SET search_path = public
AS $$
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

-- Fix submit_plan_approval function
DROP FUNCTION IF EXISTS submit_plan_approval(UUID, UUID, TEXT, TEXT);
CREATE OR REPLACE FUNCTION submit_plan_approval(
    plan_id UUID,
    mentor_id UUID,
    approval_status TEXT, -- 'approved', 'rejected', 'commented'
    feedback_text TEXT DEFAULT NULL
)
RETURNS JSONB 
SECURITY DEFINER
SET search_path = public
AS $$
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

-- Fix cleanup_expired_locks function
DROP FUNCTION IF EXISTS cleanup_expired_locks();
CREATE OR REPLACE FUNCTION cleanup_expired_locks()
RETURNS INTEGER 
SECURITY DEFINER
SET search_path = public
AS $$
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

-- Add a comment explaining the security settings
COMMENT ON FUNCTION update_updated_at_column() IS 'Automatically updates updated_at timestamp. Uses SECURITY DEFINER with search_path=public for security.';
COMMENT ON FUNCTION set_mentor_permissions() IS 'Sets default permissions based on mentor role. Uses SECURITY DEFINER with search_path=public for security.';
COMMENT ON FUNCTION handle_head_mentor_departure() IS 'Handles automatic succession when head mentor leaves. Uses SECURITY DEFINER with search_path=public for security.';
COMMENT ON FUNCTION acquire_plan_lock(UUID, UUID) IS 'Acquires edit lock for a plan with 30-minute timeout. Uses SECURITY DEFINER with search_path=public for security.';
COMMENT ON FUNCTION release_plan_lock(UUID, UUID) IS 'Releases edit lock on a plan. Uses SECURITY DEFINER with search_path=public for security.';
COMMENT ON FUNCTION extend_plan_lock(UUID, UUID) IS 'Extends edit lock by 30 minutes. Uses SECURITY DEFINER with search_path=public for security.';
COMMENT ON FUNCTION save_plan_with_approval_check(UUID, UUID, JSONB, TEXT) IS 'Saves plan changes and initiates approval workflow if needed. Uses SECURITY DEFINER with search_path=public for security.';
COMMENT ON FUNCTION submit_plan_approval(UUID, UUID, TEXT, TEXT) IS 'Submits approval/rejection for a plan. Uses SECURITY DEFINER with search_path=public for security.';
COMMENT ON FUNCTION cleanup_expired_locks() IS 'Cleans up expired edit locks. Uses SECURITY DEFINER with search_path=public for security.';