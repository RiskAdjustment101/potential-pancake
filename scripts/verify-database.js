const { createClient } = require('@supabase/supabase-js')

// Load environment variables
require('dotenv').config({ path: '.env.local' })

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL
const supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY

const supabase = createClient(supabaseUrl, supabaseAnonKey)

async function verifyDatabase() {
  console.log('🔍 Verifying Supabase database tables...\n')
  
  const tables = [
    'season_plans',
    'season_weeks', 
    'weekly_agendas',
    'parent_comms'
  ]
  
  let allTablesExist = true
  
  for (const table of tables) {
    try {
      const { data, error } = await supabase
        .from(table)
        .select('*')
        .limit(1)
      
      if (error && error.message.includes('relation')) {
        console.log(`❌ Table '${table}' - NOT FOUND`)
        allTablesExist = false
      } else {
        console.log(`✅ Table '${table}' - EXISTS`)
      }
    } catch (err) {
      console.log(`❌ Table '${table}' - ERROR:`, err.message)
      allTablesExist = false
    }
  }
  
  console.log('\n' + '='.repeat(50))
  
  if (allTablesExist) {
    console.log('🎉 SUCCESS! All database tables are created.')
    console.log('✅ Your Supabase integration is fully operational!')
    console.log('\nNext steps:')
    console.log('1. Start the development server: npm run dev')
    console.log('2. Sign in with Clerk')
    console.log('3. Start creating Season Plans!')
  } else {
    console.log('⚠️  Some tables are missing.')
    console.log('\nTroubleshooting:')
    console.log('1. Check GitHub Actions: https://github.com/RiskAdjustment101/potential-pancake/actions')
    console.log('2. If the action failed, check the logs for errors')
    console.log('3. You can manually run the SQL in Supabase SQL Editor:')
    console.log('   - Go to: https://lodmtemrzvmiihfoidrt.supabase.co')
    console.log('   - Navigate to SQL Editor')
    console.log('   - Copy content from supabase/schema.sql and run it')
  }
}

verifyDatabase()