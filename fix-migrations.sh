#!/bin/bash

echo "🔧 Fixing Supabase Migration Issues"
echo "===================================="
echo ""

PROJECT_REF="lodmtemrzvmiihfoidrt"

echo "Step 1: Link to your Supabase project"
echo "You'll need:"
echo "1. Your Supabase Access Token"
echo "2. Your database password"
echo ""

read -p "Enter your Supabase Access Token: " ACCESS_TOKEN
read -sp "Enter your database password: " DB_PASSWORD
echo ""

echo "Logging in..."
supabase login --token "$ACCESS_TOKEN"

echo "Linking to project..."
supabase link --project-ref $PROJECT_REF --password "$DB_PASSWORD"

if [ $? -ne 0 ]; then
    echo "❌ Failed to link. Please check your credentials."
    exit 1
fi

echo "✅ Project linked!"
echo ""

echo "Step 2: Repairing migration history"
supabase migration repair --status reverted 20240904

echo ""
echo "Step 3: Pulling current state from remote"
supabase db pull

echo ""
echo "Step 4: Pushing migrations"
supabase db push

echo ""
echo "✅ Migration issues resolved!"
echo ""
echo "Alternative: Run the RLS enablement SQL manually"
echo "Go to: https://supabase.com/dashboard/project/$PROJECT_REF/sql"
echo "And run the SQL from RUN_THIS_NOW.sql"