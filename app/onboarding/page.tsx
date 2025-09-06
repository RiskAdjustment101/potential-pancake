'use client'

import { useState } from 'react'
import { useUser } from '@clerk/nextjs'
import { useRouter } from 'next/navigation'
import { Card } from '@/components/ui/card'
import { Input } from '@/components/ui/input'
import { Button } from '@/components/ui/button'
import { useSupabaseAuth } from '@/lib/use-supabase-auth'
import { Sparkles, Users, Calendar, MapPin } from 'lucide-react'

export default function OnboardingPage() {
  const { user } = useUser()
  const router = useRouter()
  const { supabase } = useSupabaseAuth()
  const [loading, setLoading] = useState(false)
  const [step, setStep] = useState(1)
  
  const [formData, setFormData] = useState({
    full_name: user?.fullName || '',
    email: user?.primaryEmailAddress?.emailAddress || '',
    phone: '',
    years_mentoring: 0,
    bio: '',
    // Team info for head coaches
    team_name: '',
    team_number: '',
    team_size: 10,
    age_group: 'elementary',
    meeting_location: '',
    meeting_schedule: '',
    competition_region: '',
    role: 'head_coach' // or 'joining_team'
  })

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setLoading(true)

    try {
      // Create user profile
      const { data: profile, error: profileError } = await supabase
        .from('user_profiles')
        .insert({
          clerk_user_id: user?.id,
          email: formData.email,
          full_name: formData.full_name,
          phone: formData.phone,
          years_mentoring: formData.years_mentoring,
          bio: formData.bio
        })
        .select()
        .single()

      if (profileError) throw profileError

      // If creating a new team (head coach)
      if (formData.role === 'head_coach' && formData.team_name) {
        const { data: team, error: teamError } = await supabase
          .from('mentor_teams')
          .insert({
            team_name: formData.team_name,
            team_number: formData.team_number,
            team_size: formData.team_size,
            age_group: formData.age_group,
            meeting_location: formData.meeting_location,
            meeting_schedule: formData.meeting_schedule,
            competition_region: formData.competition_region,
            created_by_user_id: user?.id
          })
          .select()
          .single()

        if (teamError) throw teamError

        // Add creator as head coach
        const { error: mentorError } = await supabase
          .from('team_mentors')
          .insert({
            team_id: team.id,
            user_id: profile.id,
            role: 'head_coach'
          })

        if (mentorError) throw mentorError
      }

      router.push('/dashboard')
    } catch (error) {
      console.error('Error during onboarding:', error)
      alert('Error creating profile. Please try again.')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="min-h-screen bg-slate-900 px-6 py-12">
      <div className="mx-auto max-w-2xl">
        <div className="mb-8 text-center">
          <div className="mb-4 flex justify-center">
            <Sparkles className="h-12 w-12 text-orange-500" />
          </div>
          <h1 className="text-3xl font-bold text-slate-50">Welcome to FLL Mentor Copilot!</h1>
          <p className="mt-2 text-slate-400">Let's get your profile set up</p>
        </div>

        <Card className="border-slate-700 bg-slate-800 p-6">
          {step === 1 && (
            <form onSubmit={(e) => { e.preventDefault(); setStep(2); }} className="space-y-4">
              <h2 className="text-xl font-semibold text-slate-50">About You</h2>
              
              <div>
                <label className="mb-2 block text-sm text-slate-300">Full Name</label>
                <Input
                  type="text"
                  value={formData.full_name}
                  onChange={(e) => setFormData({ ...formData, full_name: e.target.value })}
                  className="border-slate-700 bg-slate-900 text-slate-50"
                  required
                />
              </div>

              <div>
                <label className="mb-2 block text-sm text-slate-300">Email</label>
                <Input
                  type="email"
                  value={formData.email}
                  onChange={(e) => setFormData({ ...formData, email: e.target.value })}
                  className="border-slate-700 bg-slate-900 text-slate-50"
                  required
                />
              </div>

              <div>
                <label className="mb-2 block text-sm text-slate-300">Phone (optional)</label>
                <Input
                  type="tel"
                  value={formData.phone}
                  onChange={(e) => setFormData({ ...formData, phone: e.target.value })}
                  className="border-slate-700 bg-slate-900 text-slate-50"
                />
              </div>

              <div>
                <label className="mb-2 block text-sm text-slate-300">Years of FLL Mentoring Experience</label>
                <Input
                  type="number"
                  min="0"
                  value={formData.years_mentoring}
                  onChange={(e) => setFormData({ ...formData, years_mentoring: parseInt(e.target.value) })}
                  className="border-slate-700 bg-slate-900 text-slate-50"
                />
              </div>

              <div>
                <label className="mb-2 block text-sm text-slate-300">Bio (optional)</label>
                <textarea
                  value={formData.bio}
                  onChange={(e) => setFormData({ ...formData, bio: e.target.value })}
                  className="w-full rounded-lg border border-slate-700 bg-slate-900 p-2 text-slate-50"
                  rows={3}
                  placeholder="Tell us about your mentoring experience..."
                />
              </div>

              <Button type="submit" className="w-full bg-blue-500 hover:bg-blue-600">
                Next: Team Setup
              </Button>
            </form>
          )}

          {step === 2 && (
            <form onSubmit={handleSubmit} className="space-y-4">
              <h2 className="text-xl font-semibold text-slate-50">Team Setup</h2>
              
              <div className="space-y-4">
                <label className="flex cursor-pointer items-center space-x-3 rounded-lg border border-slate-700 p-4 hover:bg-slate-700/50">
                  <input
                    type="radio"
                    name="role"
                    value="head_coach"
                    checked={formData.role === 'head_coach'}
                    onChange={(e) => setFormData({ ...formData, role: e.target.value })}
                    className="text-blue-500"
                  />
                  <div>
                    <div className="font-medium text-slate-50">I'm starting a new team</div>
                    <div className="text-sm text-slate-400">Create a team as head coach</div>
                  </div>
                </label>

                <label className="flex cursor-pointer items-center space-x-3 rounded-lg border border-slate-700 p-4 hover:bg-slate-700/50">
                  <input
                    type="radio"
                    name="role"
                    value="joining_team"
                    checked={formData.role === 'joining_team'}
                    onChange={(e) => setFormData({ ...formData, role: e.target.value })}
                    className="text-blue-500"
                  />
                  <div>
                    <div className="font-medium text-slate-50">I have an invite code</div>
                    <div className="text-sm text-slate-400">Join an existing team</div>
                  </div>
                </label>
              </div>

              {formData.role === 'head_coach' && (
                <>
                  <div>
                    <label className="mb-2 block text-sm text-slate-300">Team Name</label>
                    <Input
                      type="text"
                      value={formData.team_name}
                      onChange={(e) => setFormData({ ...formData, team_name: e.target.value })}
                      className="border-slate-700 bg-slate-900 text-slate-50"
                      placeholder="e.g., Robot Wizards"
                      required
                    />
                  </div>

                  <div>
                    <label className="mb-2 block text-sm text-slate-300">FLL Team Number (optional)</label>
                    <Input
                      type="text"
                      value={formData.team_number}
                      onChange={(e) => setFormData({ ...formData, team_number: e.target.value })}
                      className="border-slate-700 bg-slate-900 text-slate-50"
                      placeholder="e.g., 12345"
                    />
                  </div>

                  <div>
                    <label className="mb-2 block text-sm text-slate-300">Team Size</label>
                    <Input
                      type="number"
                      min="2"
                      max="10"
                      value={formData.team_size}
                      onChange={(e) => setFormData({ ...formData, team_size: parseInt(e.target.value) })}
                      className="border-slate-700 bg-slate-900 text-slate-50"
                    />
                  </div>

                  <div>
                    <label className="mb-2 block text-sm text-slate-300">Age Group</label>
                    <select
                      value={formData.age_group}
                      onChange={(e) => setFormData({ ...formData, age_group: e.target.value })}
                      className="w-full rounded-lg border border-slate-700 bg-slate-900 p-2 text-slate-50"
                    >
                      <option value="elementary">Elementary (6-9 years)</option>
                      <option value="middle">Middle School (9-14 years)</option>
                      <option value="mixed">Mixed Ages</option>
                    </select>
                  </div>

                  <div>
                    <label className="mb-2 block text-sm text-slate-300">Meeting Location</label>
                    <Input
                      type="text"
                      value={formData.meeting_location}
                      onChange={(e) => setFormData({ ...formData, meeting_location: e.target.value })}
                      className="border-slate-700 bg-slate-900 text-slate-50"
                      placeholder="e.g., Lincoln Elementary School, Room 201"
                    />
                  </div>

                  <div>
                    <label className="mb-2 block text-sm text-slate-300">Meeting Schedule</label>
                    <Input
                      type="text"
                      value={formData.meeting_schedule}
                      onChange={(e) => setFormData({ ...formData, meeting_schedule: e.target.value })}
                      className="border-slate-700 bg-slate-900 text-slate-50"
                      placeholder="e.g., Tuesdays 4-6pm, Saturdays 10am-12pm"
                    />
                  </div>

                  <div>
                    <label className="mb-2 block text-sm text-slate-300">Competition Region</label>
                    <Input
                      type="text"
                      value={formData.competition_region}
                      onChange={(e) => setFormData({ ...formData, competition_region: e.target.value })}
                      className="border-slate-700 bg-slate-900 text-slate-50"
                      placeholder="e.g., Northern California"
                    />
                  </div>
                </>
              )}

              {formData.role === 'joining_team' && (
                <div className="rounded-lg bg-slate-700/50 p-4">
                  <p className="text-sm text-slate-300">
                    You'll need an invite code from your head coach to join a team. 
                    For now, we'll set up your profile and you can join a team later.
                  </p>
                </div>
              )}

              <div className="flex space-x-4">
                <Button
                  type="button"
                  variant="outline"
                  onClick={() => setStep(1)}
                  className="flex-1 border-slate-700"
                >
                  Back
                </Button>
                <Button
                  type="submit"
                  disabled={loading}
                  className="flex-1 bg-blue-500 hover:bg-blue-600"
                >
                  {loading ? 'Creating...' : 'Complete Setup'}
                </Button>
              </div>
            </form>
          )}
        </Card>
      </div>
    </div>
  )
}