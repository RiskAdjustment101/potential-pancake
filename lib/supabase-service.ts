import { supabase } from './supabase'
import type { SeasonPlan, SeasonWeek, WeeklyAgenda, ParentComm } from './supabase'

export class SupabaseService {
  // Season Plans
  static async createSeasonPlan(data: Omit<SeasonPlan, 'id' | 'created_at' | 'updated_at' | 'weeks'>) {
    const { data: seasonPlan, error } = await supabase
      .from('season_plans')
      .insert(data)
      .select()
      .single()

    if (error) throw error
    return seasonPlan
  }

  static async getSeasonPlansByUserId(userId: string) {
    const { data, error } = await supabase
      .from('season_plans')
      .select(`
        *,
        season_weeks (*)
      `)
      .eq('user_id', userId)
      .order('created_at', { ascending: false })

    if (error) throw error
    return data
  }

  static async getSeasonPlanById(id: string) {
    const { data, error } = await supabase
      .from('season_plans')
      .select(`
        *,
        season_weeks (*)
      `)
      .eq('id', id)
      .single()

    if (error) throw error
    return data
  }

  static async updateSeasonPlan(id: string, updates: Partial<SeasonPlan>) {
    const { data, error } = await supabase
      .from('season_plans')
      .update(updates)
      .eq('id', id)
      .select()
      .single()

    if (error) throw error
    return data
  }

  static async deleteSeasonPlan(id: string) {
    const { error } = await supabase
      .from('season_plans')
      .delete()
      .eq('id', id)

    if (error) throw error
  }

  // Season Weeks
  static async createSeasonWeek(data: Omit<SeasonWeek, 'id' | 'created_at' | 'updated_at'>) {
    const { data: seasonWeek, error } = await supabase
      .from('season_weeks')
      .insert(data)
      .select()
      .single()

    if (error) throw error
    return seasonWeek
  }

  static async createSeasonWeeks(weeks: Omit<SeasonWeek, 'id' | 'created_at' | 'updated_at'>[]) {
    const { data, error } = await supabase
      .from('season_weeks')
      .insert(weeks)
      .select()

    if (error) throw error
    return data
  }

  static async getSeasonWeeksByPlanId(seasonPlanId: string) {
    const { data, error } = await supabase
      .from('season_weeks')
      .select('*')
      .eq('season_plan_id', seasonPlanId)
      .order('week_number', { ascending: true })

    if (error) throw error
    return data
  }

  static async updateSeasonWeek(id: string, updates: Partial<SeasonWeek>) {
    const { data, error } = await supabase
      .from('season_weeks')
      .update(updates)
      .eq('id', id)
      .select()
      .single()

    if (error) throw error
    return data
  }

  // Weekly Agendas
  static async createWeeklyAgenda(data: Omit<WeeklyAgenda, 'id' | 'created_at' | 'updated_at'>) {
    const { data: agenda, error } = await supabase
      .from('weekly_agendas')
      .insert(data)
      .select()
      .single()

    if (error) throw error
    return agenda
  }

  static async getWeeklyAgendasByUserId(userId: string) {
    const { data, error } = await supabase
      .from('weekly_agendas')
      .select(`
        *,
        season_weeks (
          title,
          week_number,
          season_plans (team_name)
        )
      `)
      .eq('user_id', userId)
      .order('meeting_date', { ascending: false })

    if (error) throw error
    return data
  }

  static async updateWeeklyAgenda(id: string, updates: Partial<WeeklyAgenda>) {
    const { data, error } = await supabase
      .from('weekly_agendas')
      .update(updates)
      .eq('id', id)
      .select()
      .single()

    if (error) throw error
    return data
  }

  static async deleteWeeklyAgenda(id: string) {
    const { error } = await supabase
      .from('weekly_agendas')
      .delete()
      .eq('id', id)

    if (error) throw error
  }

  // Parent Communications
  static async createParentComm(data: Omit<ParentComm, 'id' | 'created_at' | 'updated_at'>) {
    const { data: comm, error } = await supabase
      .from('parent_comms')
      .insert(data)
      .select()
      .single()

    if (error) throw error
    return comm
  }

  static async getParentCommsByUserId(userId: string) {
    const { data, error } = await supabase
      .from('parent_comms')
      .select(`
        *,
        season_plans (team_name)
      `)
      .eq('user_id', userId)
      .order('created_at', { ascending: false })

    if (error) throw error
    return data
  }

  static async updateParentComm(id: string, updates: Partial<ParentComm>) {
    const { data, error } = await supabase
      .from('parent_comms')
      .update(updates)
      .eq('id', id)
      .select()
      .single()

    if (error) throw error
    return data
  }

  static async deleteParentComm(id: string) {
    const { error } = await supabase
      .from('parent_comms')
      .delete()
      .eq('id', id)

    if (error) throw error
  }
}