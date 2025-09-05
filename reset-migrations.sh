#!/bin/bash

echo "🔄 Resetting Supabase Migrations"
echo "================================="
echo ""
echo "This will:"
echo "1. Link to your project"
echo "2. Mark migration 20240904 as reverted"
echo "3. Push all migrations fresh"
echo ""

PROJECT_REF="lodmtemrzvmiihfoidrt"

# Check if we have the token in environment or need to ask
if [ -z "$SUPABASE_ACCESS_TOKEN" ]; then
    echo "📝 Step 1: Authentication"
    echo "Get your token from: https://supabase.com/dashboard/account/tokens"
    read -p "Enter your Supabase Access Token: " ACCESS_TOKEN
else
    ACCESS_TOKEN=$SUPABASE_ACCESS_TOKEN
    echo "Using token from environment"
fi

# Login
echo ""
echo "Logging in to Supabase..."
supabase login --token "$ACCESS_TOKEN"

if [ $? -ne 0 ]; then
    echo "❌ Login failed. Please check your access token."
    exit 1
fi

echo "✅ Logged in successfully"

# Link project - will prompt for password
echo ""
echo "📝 Step 2: Linking to project"
echo "You'll be prompted for your database password"
echo "(The password you set when creating your Supabase project)"
echo ""

supabase link --project-ref $PROJECT_REF

if [ $? -ne 0 ]; then
    echo "❌ Failed to link project. Please check your database password."
    exit 1
fi

echo "✅ Project linked successfully"

# Repair migration
echo ""
echo "📝 Step 3: Repairing migration history"
supabase migration repair --status reverted 20240904

if [ $? -eq 0 ]; then
    echo "✅ Migration 20240904 marked as reverted"
else
    echo "⚠️  Migration repair may have failed (possibly already reverted)"
fi

# List current migrations
echo ""
echo "📝 Current local migrations:"
ls -la supabase/migrations/

# Push migrations
echo ""
echo "📝 Step 4: Pushing all migrations"
echo "This will apply:"
echo "  - Initial schema"
echo "  - RLS policies" 
echo "  - RLS enablement"
echo "  - Function security fix"
echo ""

supabase db push

if [ $? -eq 0 ]; then
    echo ""
    echo "🎉 SUCCESS! All migrations applied!"
    echo ""
    echo "✅ Tables created"
    echo "✅ RLS enabled" 
    echo "✅ Security policies applied"
    echo ""
    echo "Verify in dashboard: https://supabase.com/dashboard/project/$PROJECT_REF/editor"
    echo "All tables should show 🔒 icon"
else
    echo ""
    echo "❌ Migration push failed"
    echo ""
    echo "Try running the SQL manually:"
    echo "1. Go to: https://supabase.com/dashboard/project/$PROJECT_REF/sql"
    echo "2. Run the contents of ENABLE_RLS_NOW.sql"
fi