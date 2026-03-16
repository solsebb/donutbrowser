# TwitterBrowser Hosted Auth with Supabase

This fork supports three sync/auth modes:

- Local only
- Self-hosted sync with `SYNC_TOKEN`
- Hosted auth + hosted sync with Supabase Auth, Supabase Postgres, and `donut-sync`

## What Supabase owns

- User identity
- Hosted account metadata in `public.user_profiles`
- Hosted sync enable/disable state
- Issuing short-lived RS256 sync JWTs through the `issue-sync-token` Edge Function

## What `donut-sync` still owns

- Profile payload storage in S3 / MinIO
- Presigned upload/download URLs
- JWT validation for hosted sync

For the public hosted deployment path, see [docs/hosted-sync-railway-r2.md](/Users/benjamingouleau/Downloads/donutbrowser/docs/hosted-sync-railway-r2.md).

## Desktop env

Set these in the TwitterBrowser desktop environment:

```bash
TWITTERBROWSER_SUPABASE_URL=
TWITTERBROWSER_SUPABASE_ANON_KEY=
TWITTERBROWSER_SUPABASE_REDIRECT_URL=twitterbrowser://auth/callback
TWITTERBROWSER_CLOUD_SYNC_URL=
```

## `donut-sync` env

Set these in `donut-sync/.env`:

```bash
SYNC_JWT_PUBLIC_KEY=
SUPABASE_URL=
SUPABASE_SERVICE_ROLE_KEY=
```

For self-hosted token mode instead of hosted Supabase mode:

```bash
SYNC_TOKEN=
```

## Supabase secrets

Set these in the Supabase project for the Edge Function:

```bash
SYNC_JWT_PRIVATE_KEY=
SUPABASE_SERVICE_ROLE_KEY=
```

`SYNC_JWT_PRIVATE_KEY` must match the public key configured in `donut-sync` as `SYNC_JWT_PUBLIC_KEY`.

## Apply database schema

The schema lives in:

- `supabase/migrations/20260315223500_hosted_auth_user_profiles.sql`

Apply it with:

```bash
pnpm supabase:db:push
```

Or against a remote database URL:

```bash
supabase db push --db-url "postgresql://..."
```

## Deploy the Edge Function

The hosted sync token function lives in:

- `supabase/functions/issue-sync-token/index.ts`

Serve locally:

```bash
pnpm supabase:functions:serve
```

Deploy remotely:

```bash
supabase functions deploy issue-sync-token --project-ref <project-ref> --use-api
```

## OAuth redirect

Google should redirect to Supabase:

```text
https://errzkrimnulrgcjyiydb.supabase.co/auth/v1/callback
```

Supabase should then redirect back into the desktop app with:

```text
twitterbrowser://auth/callback
```
