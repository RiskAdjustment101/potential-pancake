const { createClient } = require('@supabase/supabase-js')
const fs = require('fs')
const path = require('path')

// Load environment variables
require('dotenv').config({ path: '.env.local' })

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL
const supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY

if (!supabaseUrl || !supabaseAnonKey) {
  console.error('❌ Missing Supabase credentials')
  process.exit(1)
}

console.log('⚠️  NOTE: This script uses the anon key which has limited permissions.')
console.log('For initial schema setup, you should:')
console.log('1. Go to your Supabase dashboard: https://lodmtemrzvmiihfoidrt.supabase.co')
console.log('2. Navigate to SQL Editor')
console.log('3. Copy and paste the contents of supabase/schema.sql')
console.log('4. Run the SQL to create tables and policies')
console.log('')

// Read schema file
const schemaPath = path.join(__dirname, '..', 'supabase', 'schema.sql')
const schema = fs.readFileSync(schemaPath, 'utf8')

console.log('📄 Schema file content:')
console.log('─'.repeat(50))
console.log(schema)
console.log('─'.repeat(50))
console.log('')
console.log('Copy the above SQL and run it in your Supabase SQL Editor.')