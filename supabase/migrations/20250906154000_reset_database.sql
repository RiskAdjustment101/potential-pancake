-- Reset Database - Drop all existing tables and start fresh
-- This migration safely drops all tables and recreates the mentor system

-- Drop all existing tables (order matters due to foreign keys)
DROP TABLE IF EXISTS communication_approvals CASCADE;
DROP TABLE IF EXISTS agenda_approvals CASCADE;
DROP TABLE IF EXISTS team_succession CASCADE;
DROP TABLE IF EXISTS mentor_invites CASCADE;
DROP TABLE IF EXISTS team_mentors CASCADE;
DROP TABLE IF EXISTS parent_comms CASCADE;
DROP TABLE IF EXISTS weekly_agendas CASCADE;
DROP TABLE IF EXISTS season_weeks CASCADE;
DROP TABLE IF EXISTS season_plans CASCADE;
DROP TABLE IF EXISTS mentor_teams CASCADE;
DROP TABLE IF EXISTS user_profiles CASCADE;

-- Drop any existing functions
DROP FUNCTION IF EXISTS update_updated_at_column() CASCADE;
DROP FUNCTION IF EXISTS handle_profile_updated() CASCADE;