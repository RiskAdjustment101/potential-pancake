-- Migration: 20240904_004_fix_function_security
-- Fix security warning: Set immutable search_path for update_updated_at_column function

-- Drop and recreate the function with a fixed search_path
DROP FUNCTION IF EXISTS update_updated_at_column() CASCADE;

-- Recreate function with security definer and fixed search_path
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER 
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;

-- Recreate all triggers that use this function
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

-- Add comment explaining the function
COMMENT ON FUNCTION update_updated_at_column() IS 'Automatically updates the updated_at timestamp when a row is modified';