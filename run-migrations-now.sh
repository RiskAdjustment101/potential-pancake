#!/bin/bash

echo "🚀 Running Supabase Migrations Locally"
echo "======================================"
echo ""

# Check if user has token
if [ -z "$1" ]; then
    echo "Usage: ./run-migrations-now.sh YOUR_SUPABASE_ACCESS_TOKEN"
    echo ""
    echo "Get your token from: https://supabase.com/dashboard/account/tokens"
    exit 1
fi

ACCESS_TOKEN=$1
PROJECT_REF="lodmtemrzvmiihfoidrt"

echo "📝 Logging in to Supabase..."
supabase login --token "$ACCESS_TOKEN"

if [ $? -ne 0 ]; then
    echo "❌ Login failed. Please check your token."
    exit 1
fi

echo "✅ Login successful!"
echo ""

echo "📝 Linking to project: $PROJECT_REF"
echo "When prompted for password, enter your database password"
echo "(You set this when creating the Supabase project)"
echo ""

supabase link --project-ref $PROJECT_REF

if [ $? -ne 0 ]; then
    echo "❌ Linking failed."
    echo ""
    echo "Alternative: Run migrations manually in SQL Editor"
    echo "1. Go to: https://supabase.com/dashboard/project/$PROJECT_REF/sql"
    echo "2. Copy and run each file from supabase/migrations/"
    exit 1
fi

echo "✅ Project linked!"
echo ""

echo "📝 Pushing migrations..."
supabase db push

if [ $? -eq 0 ]; then
    echo ""
    echo "🎉 SUCCESS! All migrations deployed!"
    echo ""
    echo "Verify in Supabase dashboard:"
    echo "https://supabase.com/dashboard/project/$PROJECT_REF/editor"
    echo ""
    echo "All tables should show 🔒 icon (RLS enabled)"
else
    echo ""
    echo "⚠️  Migration push had issues."
    echo ""
    echo "Try running manually in SQL Editor:"
    echo "https://supabase.com/dashboard/project/$PROJECT_REF/sql"
    echo ""
    echo "Run these files in order:"
    echo "1. supabase/migrations/20240904_001_initial_schema.sql"
    echo "2. supabase/migrations/20240904_002_rls_policies.sql"
    echo "3. supabase/migrations/20240904_003_enable_rls.sql"
    echo "4. supabase/migrations/20240904_004_fix_function_security.sql"
fi