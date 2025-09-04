# Supabase Setup Guide

This guide walks you through setting up Supabase for the FLL Mentor Copilot project.

## 1. Create Supabase Project

1. Go to [https://supabase.com](https://supabase.com) and create an account
2. Create a new project
3. Wait for the project to initialize (this takes a few minutes)

## 2. Configure Environment Variables

1. In your Supabase project dashboard, go to Settings > API
2. Copy the following values:
   - **Project URL** (starts with https://...)
   - **Anon public key** (starts with eyJ...)

3. Update `.env.local` with your actual values:
```env
NEXT_PUBLIC_SUPABASE_URL=https://your-project-ref.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

## 3. Set Up Database Schema

1. In your Supabase project dashboard, go to SQL Editor
2. Copy and paste the contents of `supabase/schema.sql`
3. Run the SQL to create all tables, indexes, and security policies

## 4. Configure Clerk + Supabase Integration

### In Clerk Dashboard:
1. Go to your Clerk project dashboard
2. Navigate to JWT Templates
3. Create a new template named "supabase"
4. Use this configuration:
```json
{
  "iss": "https://your-clerk-frontend-api",
  "sub": "{{user.id}}",
  "aud": "authenticated",
  "exp": {{date.now + 3600}},
  "iat": {{date.now}},
  "user_metadata": {
    "email": "{{user.primary_email_address.email_address}}",
    "email_verified": {{user.primary_email_address.verification.status == "verified"}},
    "phone_verified": {{user.primary_phone_number.verification.status == "verified"}},
    "sub": "{{user.id}}"
  },
  "app_metadata": {
    "provider": "clerk",
    "providers": ["clerk"]
  }
}
```

### In Supabase Dashboard:
1. Go to Authentication > Settings
2. Scroll down to "JWT Settings"
3. Set JWT Secret to match your Clerk JWT template secret
4. Enable "Use custom JWT secret"

## 5. Test the Integration

Run the development server:
```bash
npm run dev
```

The application should now be able to:
- Authenticate users with Clerk
- Store and retrieve data in Supabase with proper Row Level Security
- Automatically associate data with the authenticated user

## 6. Database Tables Created

The schema creates these tables:
- `season_plans` - Main season planning data
- `season_weeks` - Individual week details within a season
- `weekly_agendas` - Meeting agendas for specific dates
- `parent_comms` - Email communications to parents

All tables have Row Level Security enabled, ensuring users can only access their own data.

## 7. Usage in Components

Use the custom hook for authenticated Supabase access:
```tsx
import { useSupabaseAuth } from '@/lib/use-supabase-auth'

function MyComponent() {
  const { supabase, userId } = useSupabaseAuth()
  
  // Now you can make authenticated requests
  const { data } = await supabase
    .from('season_plans')
    .select('*')
}
```

Or use the service layer:
```tsx
import { SupabaseService } from '@/lib/supabase-service'

// Create a new season plan
const seasonPlan = await SupabaseService.createSeasonPlan({
  user_id: userId,
  team_name: "Awesome Robots",
  team_size: 8,
  meeting_frequency: "weekly",
  competition_date: "2024-12-15"
})
```