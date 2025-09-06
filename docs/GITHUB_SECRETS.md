# GitHub Secrets Setup for Supabase Migrations

To enable automatic Supabase migrations via GitHub Actions, you need to configure the following secrets in your GitHub repository:

## Required GitHub Secrets

1. **SUPABASE_ACCESS_TOKEN**
   - Get from: https://supabase.com/dashboard/account/tokens
   - Create a new access token with appropriate permissions
   - This authenticates the Supabase CLI

2. **SUPABASE_PROJECT_ID**
   - Your project ID: `lodmtemrzvmiihfoidrt`
   - Found in your Supabase project settings

3. **SUPABASE_DB_URL**
   - Format: `postgresql://postgres:[YOUR-PASSWORD]@db.lodmtemrzvmiihfoidrt.supabase.co:5432/postgres`
   - Get from: Supabase Dashboard > Settings > Database
   - Use the "Connection string" (not the pooler URL)
   - Replace `[YOUR-PASSWORD]` with your database password

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

## Current Migration Files

- `supabase/migrations/20250906101655_initial_schema.sql` - Initial database schema with tables and RLS policies