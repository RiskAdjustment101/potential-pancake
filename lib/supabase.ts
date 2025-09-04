import { createClient } from '@supabase/supabase-js'

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!
const supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!

if (!supabaseUrl || !supabaseAnonKey) {
  throw new Error('Missing Supabase environment variables')
}

export const supabase = createClient(supabaseUrl, supabaseAnonKey)

// Database Types
export interface SeasonPlan {
  id: string
  user_id: string
  team_name: string
  team_size: number
  meeting_frequency: 'weekly' | 'bi-weekly'
  competition_date: string
  weeks: SeasonWeek[]
  created_at: string
  updated_at: string
}

export interface SeasonWeek {
  id: string
  season_plan_id: string
  week_number: number
  title: string
  description: string
  goals: string[]
  activities: string[]
  supplies_needed: string[]
  created_at: string
  updated_at: string
}

export interface WeeklyAgenda {
  id: string
  user_id: string
  season_week_id: string
  meeting_date: string
  warmup: string
  build_activity: string
  coding_activity: string
  reflection: string
  notes: string
  created_at: string
  updated_at: string
}

export interface ParentComm {
  id: string
  user_id: string
  season_plan_id: string
  subject: string
  content: string
  send_date: string
  created_at: string
  updated_at: string
}