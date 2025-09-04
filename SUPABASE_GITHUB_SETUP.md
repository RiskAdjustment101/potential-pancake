# Supabase GitHub Integration Setup

This guide sets up automatic Supabase migrations when you push to the main branch.

## ✅ What's Already Done

- Created migration files in `supabase/migrations/`
- Set up GitHub Actions workflow for automatic deployment
- Configured Supabase project structure

## 🔧 Setup Steps

### 1. Get Supabase Access Token

1. Go to [Supabase Dashboard](https://supabase.com/dashboard/account/tokens)
2. Create a new access token with full permissions
3. Copy the token (starts with `sbp_`)

### 2. Get Project Reference ID

1. Go to your project: https://lodmtemrzvmiihfoidrt.supabase.co
2. Go to Settings → General
3. Copy your "Reference ID" (looks like: `lodmtemrzvmiihfoidrt`)

### 3. Configure GitHub Secrets

1. Go to your GitHub repository
2. Navigate to Settings → Secrets and Variables → Actions
3. Add these repository secrets:
   - `SUPABASE_ACCESS_TOKEN`: Your access token from step 1
   - `SUPABASE_PROJECT_REF`: Your reference ID from step 2

### 4. Push to Trigger Deployment

```bash
git add .
git commit -m "Add Supabase migrations and GitHub integration"
git push origin main
```

The GitHub Action will automatically:
- Link to your Supabase project
- Run all migrations in `supabase/migrations/`
- Deploy schema changes to your database

## 🔄 How It Works

1. **Migration Files**: Each `.sql` file in `supabase/migrations/` is a timestamped migration
2. **GitHub Actions**: Watches for changes to `supabase/` directory
3. **Automatic Deployment**: Runs `supabase db push` on every main branch push
4. **Rollback Safety**: Migrations are immutable - only add new ones

## 📁 Migration Structure

```
supabase/
├── config.toml                    # Supabase configuration
└── migrations/
    ├── 20240904_001_initial_schema.sql    # Core tables
    └── 20240904_002_rls_policies.sql      # Security policies
```

## 🚀 Adding New Migrations

To add new database changes:

1. Create a new migration file:
   ```bash
   # Format: YYYYMMDD_NNN_description.sql
   touch supabase/migrations/20240905_003_add_user_preferences.sql
   ```

2. Add your SQL changes:
   ```sql
   -- New migration: 20240905_003_add_user_preferences
   CREATE TABLE user_preferences (
       id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
       user_id TEXT NOT NULL,
       theme TEXT DEFAULT 'dark',
       created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
   );
   ```

3. Commit and push:
   ```bash
   git add supabase/migrations/
   git commit -m "Add user preferences table"
   git push origin main
   ```

4. GitHub Actions will automatically deploy the new migration!

## 🔍 Monitoring Deployments

- Check GitHub Actions tab for deployment status
- View logs in Supabase Dashboard → Logs
- Database changes appear immediately after successful deployment

## 🛠️ Manual Migration (Fallback)

If GitHub Actions fails, you can run migrations manually:

```bash
# Install Supabase CLI
npm install -g supabase

# Link your project
supabase link --project-ref lodmtemrzvmiihfoidrt

# Deploy migrations
supabase db push
```

## ⚠️ Important Notes

- **Never edit existing migration files** - create new ones instead
- **Test migrations locally** before pushing to main
- **Migrations are irreversible** - plan schema changes carefully
- **Use descriptive filenames** for easier tracking