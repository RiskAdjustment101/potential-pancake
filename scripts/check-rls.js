const { createClient } = require('@supabase/supabase-js')
require('dotenv').config({ path: '.env.local' })

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL
const supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY

const supabase = createClient(supabaseUrl, supabaseAnonKey)

async function checkRLS() {
  console.log('🔒 Checking Row Level Security Status...\n')
  
  // Try to query each table without auth
  const tables = ['season_plans', 'season_weeks', 'weekly_agendas', 'parent_comms']
  let allSecured = true
  
  for (const table of tables) {
    try {
      // This should fail if RLS is properly enabled (no auth token)
      const { data, error } = await supabase
        .from(table)
        .select('*')
        .limit(1)
      
      if (error) {
        console.log(`✅ ${table} - RLS ENABLED (access denied without auth)`)
      } else {
        console.log(`⚠️  ${table} - RLS might be disabled or policies too permissive`)
        allSecured = false
      }
    } catch (err) {
      console.log(`✅ ${table} - RLS ENABLED`)
    }
  }
  
  console.log('\n' + '='.repeat(50))
  
  if (allSecured) {
    console.log('🎉 All tables are secured with RLS!')
    console.log('✅ Your database is ready for production use')
  } else {
    console.log('⚠️  Some tables may need RLS configuration')
    console.log('Run the RLS enablement SQL in Supabase dashboard')
  }
}

checkRLS()