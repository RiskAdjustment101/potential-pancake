#!/bin/bash

echo "🚀 Supabase CLI Setup Script"
echo "============================"
echo ""
echo "This script will help you link your local project to Supabase."
echo ""
echo "📝 Step 1: Get your Supabase Access Token"
echo "   1. Go to: https://supabase.com/dashboard/account/tokens"
echo "   2. Create a new token (if you don't have one)"
echo "   3. Copy the token (starts with 'sbp_')"
echo ""
read -p "Paste your Supabase Access Token: " ACCESS_TOKEN

if [[ -z "$ACCESS_TOKEN" ]]; then
    echo "❌ No token provided. Exiting..."
    exit 1
fi

echo ""
echo "📝 Step 2: Linking to your remote project"
echo "   Project ID: lodmtemrzvmiihfoidrt"
echo ""

# Login with token
echo "Logging in..."
supabase login --token "$ACCESS_TOKEN"

if [ $? -eq 0 ]; then
    echo "✅ Login successful!"
else
    echo "❌ Login failed. Please check your token."
    exit 1
fi

# Link to remote project
echo ""
echo "Linking to remote project..."
supabase link --project-ref lodmtemrzvmiihfoidrt

if [ $? -eq 0 ]; then
    echo "✅ Successfully linked to remote project!"
else
    echo "❌ Linking failed. Please check your project ID."
    exit 1
fi

# Push migrations
echo ""
echo "📝 Step 3: Push database migrations"
read -p "Do you want to push migrations now? (y/n): " PUSH_MIGRATIONS

if [[ "$PUSH_MIGRATIONS" == "y" || "$PUSH_MIGRATIONS" == "Y" ]]; then
    echo "Pushing migrations..."
    supabase db push
    
    if [ $? -eq 0 ]; then
        echo "✅ Migrations pushed successfully!"
    else
        echo "⚠️  Migration push failed. You can run 'supabase db push' manually later."
    fi
fi

echo ""
echo "🎉 Setup Complete!"
echo ""
echo "Useful commands:"
echo "  supabase db push         - Push local migrations to remote"
echo "  supabase db pull         - Pull remote schema to local"
echo "  supabase db status       - Check migration status"
echo "  supabase db reset        - Reset local database"
echo ""
echo "Your remote database URL: https://supabase.com/dashboard/project/lodmtemrzvmiihfoidrt"