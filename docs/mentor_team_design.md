# Multi-Mentor Team System Design

## 🎯 Core Requirements

1. **Invitations**: Head mentor + mentors with invite permission
2. **Leadership Transfer**: Automatic assignment to another mentor when head leaves
3. **Edit Conflicts**: Lock-based editing with approval workflow
4. **Team Settings**: Meeting schedules, communication preferences

## 🗄️ Database Schema

### Updated Schema with Requirements

```sql
-- Mentors (individual people)
mentors (
  id UUID PRIMARY KEY,
  clerk_user_id TEXT UNIQUE NOT NULL,
  first_name TEXT NOT NULL,
  last_name TEXT NOT NULL,
  email TEXT NOT NULL,
  phone TEXT,
  organization TEXT,
  years_coaching INTEGER DEFAULT 0,
  experience_level TEXT CHECK (experience_level IN ('beginner', 'intermediate', 'advanced')),
  timezone TEXT DEFAULT 'America/New_York',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Teams (can have multiple mentors)
teams (
  id UUID PRIMARY KEY,
  team_name TEXT NOT NULL,
  team_number INTEGER UNIQUE,
  organization TEXT,
  student_count INTEGER CHECK (student_count > 0),
  age_group TEXT CHECK (age_group IN ('explore', 'challenge', 'discover')),
  
  -- Team Settings
  meeting_frequency TEXT CHECK (meeting_frequency IN ('weekly', 'bi-weekly', 'custom')),
  meeting_day TEXT, -- Monday, Tuesday, etc
  meeting_time TIME,
  meeting_duration INTEGER, -- minutes
  meeting_location TEXT,
  
  -- Communication Settings
  parent_email_enabled BOOLEAN DEFAULT true,
  weekly_updates BOOLEAN DEFAULT true,
  reminder_notifications BOOLEAN DEFAULT true,
  
  -- Competition Info
  competition_date DATE,
  competition_location TEXT,
  
  -- Status
  active BOOLEAN DEFAULT true,
  current_season TEXT, -- "2024-2025"
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Junction: Mentors ↔ Teams with roles
team_mentors (
  id UUID PRIMARY KEY,
  team_id UUID REFERENCES teams(id) ON DELETE CASCADE,
  mentor_id UUID REFERENCES mentors(id) ON DELETE CASCADE,
  
  -- Role & Status
  role TEXT NOT NULL CHECK (role IN ('head_mentor', 'assistant_mentor', 'technical_advisor', 'guest')),
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'pending_invitation')),
  
  -- Permissions
  can_invite_mentors BOOLEAN DEFAULT false,
  can_edit_plans BOOLEAN DEFAULT true,
  can_send_emails BOOLEAN DEFAULT false,
  can_manage_settings BOOLEAN DEFAULT false,
  
  -- Metadata
  invited_by_mentor_id UUID REFERENCES mentors(id),
  joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  invited_at TIMESTAMP WITH TIME ZONE,
  
  UNIQUE(team_id, mentor_id)
);

-- Season Plans (with edit locking and approval system)
season_plans (
  id UUID PRIMARY KEY,
  team_id UUID REFERENCES teams(id) ON DELETE CASCADE,
  created_by_mentor_id UUID REFERENCES mentors(id),
  
  -- Plan Details
  plan_name TEXT NOT NULL,
  season_year TEXT NOT NULL,
  total_weeks INTEGER DEFAULT 16,
  
  -- Edit Control
  currently_editing_mentor_id UUID REFERENCES mentors(id), -- NULL = not locked
  locked_at TIMESTAMP WITH TIME ZONE,
  lock_expires_at TIMESTAMP WITH TIME ZONE,
  
  -- Approval System
  status TEXT DEFAULT 'draft' CHECK (status IN ('draft', 'pending_approval', 'approved', 'archived')),
  requires_approval BOOLEAN DEFAULT false, -- Set if multiple mentors edited
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Plan Approval System
plan_approvals (
  id UUID PRIMARY KEY,
  season_plan_id UUID REFERENCES season_plans(id) ON DELETE CASCADE,
  mentor_id UUID REFERENCES mentors(id),
  
  -- Approval Details
  status TEXT CHECK (status IN ('pending', 'approved', 'rejected', 'commented')),
  feedback TEXT,
  approved_at TIMESTAMP WITH TIME ZONE,
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  UNIQUE(season_plan_id, mentor_id)
);

-- Plan Edit History (track changes for conflict resolution)
plan_edit_history (
  id UUID PRIMARY KEY,
  season_plan_id UUID REFERENCES season_plans(id) ON DELETE CASCADE,
  edited_by_mentor_id UUID REFERENCES mentors(id),
  
  -- Change Details
  changes_made JSONB, -- What was changed
  version_number INTEGER,
  edit_summary TEXT,
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Team Invitations
team_invitations (
  id UUID PRIMARY KEY,
  team_id UUID REFERENCES teams(id) ON DELETE CASCADE,
  invited_by_mentor_id UUID REFERENCES mentors(id),
  
  -- Invitation Details
  email TEXT NOT NULL,
  proposed_role TEXT CHECK (proposed_role IN ('assistant_mentor', 'technical_advisor', 'guest')),
  invitation_token UUID DEFAULT uuid_generate_v4(),
  
  -- Permissions for invited role
  can_invite_mentors BOOLEAN DEFAULT false,
  can_edit_plans BOOLEAN DEFAULT true,
  can_send_emails BOOLEAN DEFAULT false,
  can_manage_settings BOOLEAN DEFAULT false,
  
  -- Status
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'rejected', 'expired')),
  expires_at TIMESTAMP WITH TIME ZONE DEFAULT (NOW() + INTERVAL '7 days'),
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

## 🔒 Edit Locking System

### How It Works:
1. **Mentor starts editing** → Plan gets locked to them for 30 minutes
2. **Auto-save every 30 seconds** → Extends lock
3. **Manual save** → Releases lock immediately
4. **Lock expires** → Auto-release, other mentors can edit

### Conflict Resolution:
```sql
-- Function to acquire edit lock
CREATE OR REPLACE FUNCTION acquire_plan_lock(plan_id UUID, mentor_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
  lock_acquired BOOLEAN := false;
BEGIN
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
  RETURN lock_acquired;
END;
$$ LANGUAGE plpgsql;
```

## 🎭 Role-Based Permissions

### Permission Matrix:
| Role | Invite Mentors | Edit Plans | Send Emails | Manage Settings | Override Approvals |
|------|---------------|------------|-------------|-----------------|-------------------|
| Head Mentor | ✅ | ✅ | ✅ | ✅ | ✅ |
| Assistant (w/ invite perm) | ✅ | ✅ | ❌ | ❌ | ❌ |
| Assistant (regular) | ❌ | ✅ | ❌ | ❌ | ❌ |
| Technical Advisor | ❌ | ✅ | ❌ | ❌ | ❌ |
| Guest | ❌ | ❌ | ❌ | ❌ | ❌ |

### Head Mentor Succession:
```sql
-- Function called when head mentor leaves
CREATE OR REPLACE FUNCTION handle_head_mentor_departure(team_id UUID, departing_mentor_id UUID)
RETURNS UUID AS $$
DECLARE
  new_head_mentor_id UUID;
BEGIN
  -- Find the most senior assistant mentor
  SELECT mentor_id INTO new_head_mentor_id
  FROM team_mentors 
  WHERE team_id = team_id 
    AND mentor_id != departing_mentor_id
    AND role IN ('assistant_mentor', 'technical_advisor')
    AND status = 'active'
  ORDER BY joined_at ASC
  LIMIT 1;
  
  -- Promote to head mentor
  IF new_head_mentor_id IS NOT NULL THEN
    UPDATE team_mentors 
    SET 
      role = 'head_mentor',
      can_invite_mentors = true,
      can_send_emails = true,
      can_manage_settings = true
    WHERE team_id = team_id AND mentor_id = new_head_mentor_id;
  END IF;
  
  RETURN new_head_mentor_id;
END;
$$ LANGUAGE plpgsql;
```

## 📋 Approval Workflow

### When Approval is Required:
1. Multiple mentors have edited the same plan
2. Major changes to competition dates/team structure
3. Head mentor can force approval requirement

### Approval Process:
1. **Mentor saves changes** → Plan status = 'pending_approval'
2. **All team mentors notified** → Email + dashboard notification
3. **Mentors review and vote** → Approve/Reject/Comment
4. **Head mentor can override** → Force approval if needed
5. **Plan approved** → Status = 'approved', goes live

## 🎯 User Experience Examples

### Editing Conflict:
```
Sarah opens Season Plan → Gets edit lock
Mike tries to edit → "Plan is being edited by Sarah. Lock expires in 23 minutes."
Sarah saves → Lock released
Mike can now edit → Gets new lock
```

### Invitation Flow:
```
Head Mentor → "Invite Co-Mentor" → Enter email + role
System → Sends invitation email with magic link
Invitee → Clicks link → Signs up/logs in → Joins team
All mentors → Notification: "Lisa joined as Technical Advisor"
```

### Team Settings Management:
```
Head Mentor → Team Settings → 
  - Meeting: Tuesdays 6PM-8PM
  - Notifications: Weekly digest enabled
  - Parent emails: Automated reminders on
Assistant Mentors → See settings but cannot edit
```

Does this design capture your requirements? Should we start implementing the mentor profile and team creation flow first?