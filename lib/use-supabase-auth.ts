'use client'

import { useAuth } from '@clerk/nextjs'
import { createClient } from '@supabase/supabase-js'
import { useMemo } from 'react'

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!
const supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!

/**
 * Custom hook that creates a Supabase client with Clerk authentication
 * This ensures that all Supabase requests are authenticated with the current user's Clerk token
 */
export function useSupabaseAuth() {
  const { getToken, userId } = useAuth()

  const supabase = useMemo(() => {
    return createClient(supabaseUrl, supabaseAnonKey, {
      global: {
        // Function that returns the Clerk JWT token
        fetch: async (url, options = {}) => {
          const clerkToken = await getToken({ template: 'supabase' })
          
          // Insert the Clerk token into the Authorization header
          const headers = new Headers(options?.headers)
          if (clerkToken) {
            headers.set('Authorization', `Bearer ${clerkToken}`)
          }

          return fetch(url, {
            ...options,
            headers,
          })
        },
      },
    })
  }, [getToken])

  return {
    supabase,
    userId,
  }
}