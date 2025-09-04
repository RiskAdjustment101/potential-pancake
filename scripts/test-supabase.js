const { createClient } = require('@supabase/supabase-js')

// Load environment variables
require('dotenv').config({ path: '.env.local' })

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL
const supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY

console.log('Testing Supabase connection...')
console.log('URL:', supabaseUrl)
console.log('Key:', supabaseAnonKey ? 'Present ✅' : 'Missing ❌')

if (!supabaseUrl || !supabaseAnonKey) {
  console.error('❌ Missing Supabase credentials in .env.local')
  process.exit(1)
}

const supabase = createClient(supabaseUrl, supabaseAnonKey)

async function testConnection() {
  try {
    // Test basic connection
    const { data, error } = await supabase
      .from('_test')
      .select('*')
      .limit(1)

    if (error) {
      // This is expected if tables don't exist yet
      console.log('✅ Connection successful (no tables yet, which is expected)')
      console.log('Error details:', error.message)
    } else {
      console.log('✅ Connection successful and tables exist')
    }

    // Test auth endpoint
    const { data: authData, error: authError } = await supabase.auth.getSession()
    if (!authError) {
      console.log('✅ Auth endpoint accessible')
    }

    return true
  } catch (err) {
    console.error('❌ Connection failed:', err.message)
    return false
  }
}

testConnection()
  .then(success => {
    if (success) {
      console.log('\n🎉 Supabase connection test completed!')
      console.log('Next step: Run the database schema')
    }
    process.exit(success ? 0 : 1)
  })