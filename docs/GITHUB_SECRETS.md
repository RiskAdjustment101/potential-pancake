# GitHub Secrets Setup for Supabase Migrations

To enable automatic Supabase migrations via GitHub Actions, you need to configure the following secrets in your GitHub repository:

## Required GitHub Secrets

1. **SUPABASE_ACCESS_TOKEN**
   - Get from: https://supabase.com/dashboard/account/tokens
   - Create a new personal access token
   - This authenticates the Supabase CLI with the Management API

2. **SUPABASE_PROJECT_REF** 
   - Your project reference ID: `lodmtemrzvmiihfoidrt`
   - Found in your Supabase project URL or Settings

3. **SUPABASE_DB_PASSWORD**
   - Your Postgres `postgres` user password
   - Get from: Supabase Dashboard > Settings > Database
   - This is the database password, NOT an API key
   - If forgotten, you can reset it from the dashboard

## How to Add Secrets to GitHub

1. Go to your GitHub repository
2. Navigate to **Settings** > **Secrets and variables** > **Actions**
3. Click **New repository secret**
4. Add each secret with the exact name and value

## Testing the Workflow

Once secrets are configured:

1. The workflow triggers automatically when:
   - Files in `supabase/migrations/` are changed
   - The workflow file itself is modified
   - Pushed to the `main` branch

2. Or manually trigger:
   - Go to **Actions** tab
   - Select "Supabase Migrations" workflow
   - Click "Run workflow"

## Security Notes

- Never commit these values to your repository
- Use GitHub's secret management for all sensitive data
- Rotate tokens periodically
- The SUPABASE_DB_URL contains your database password - handle with care

## Workflows

We have two workflows:

1. **Deploy Database Migrations** (`supabase-migrations-deploy.yml`)
   - Triggers on push to `main` branch
   - Applies migrations to production database
   - Uses: SUPABASE_ACCESS_TOKEN, SUPABASE_DB_PASSWORD, SUPABASE_PROJECT_REF

2. **Validate Database Migrations** (`supabase-migrations-validate.yml`)
   - Triggers on pull requests
   - Tests migrations locally for syntax/ordering issues
   - No secrets required (runs locally)

## Current Migration Files

- `supabase/migrations/20250906101655_initial_schema.sql` - Initial database schema with tables and RLS policies

## Troubleshooting

- **"password authentication failed"**: You need SUPABASE_DB_PASSWORD (the Postgres password), not API keys
- **"connection refused"**: May be temporarily banned after failed attempts. Wait 30 minutes or use `supabase network-bans remove`
- **Interactive prompts in CI**: Ensure all three secrets are set correctly