# TwitterBrowser Public Hosted Sync on Railway + Cloudflare R2

This guide finishes the hosted sync stack for TwitterBrowser:

- Supabase stays the control plane for auth and sync JWT issuance
- `donut-sync` runs publicly on Railway
- profile payloads live in Cloudflare R2

## Architecture

- Desktop app signs in through Supabase Auth
- Supabase Edge Function `issue-sync-token` mints a short-lived RS256 sync JWT
- TwitterBrowser sends sync requests to the public `donut-sync` URL
- `donut-sync` validates the JWT and stores objects in R2
- `donut-sync` updates `public.user_profiles.cloud_profiles_used` through the Supabase service role key

## 1. Generate a fresh hosted sync JWT keypair

Generate a new keypair outside the repo:

```bash
cd /Users/benjamingouleau/Downloads/donutbrowser
pnpm sync:keys:generate
```

This creates:

- `sync-jwt-private.pem`
- `sync-jwt-public.pem`

The private key is for Supabase.
The public key is for Railway.

## 2. Store the private key in Supabase

Set the private key secret on the linked project:

```bash
cd /Users/benjamingouleau/Downloads/donutbrowser
supabase secrets set SYNC_JWT_PRIVATE_KEY="$(cat /path/to/sync-jwt-private.pem)"
supabase functions deploy issue-sync-token --project-ref errzkrimnulrgcjyiydb --use-api
```

The function now signs sync JWTs with the fresh keypair.

## 3. Create the R2 bucket

In Cloudflare:

1. Open `R2 Object Storage`
2. Create a bucket named `twitterbrowser-sync`
3. Choose an EU jurisdiction if you want the bucket pinned to Europe
4. Create an R2 API token with read and write access to that bucket
5. Record:
   - `account id`
   - `access key id`
   - `secret access key`

R2 runtime values:

- EU jurisdiction endpoint:
  - `https://<account-id>.eu.r2.cloudflarestorage.com`
- Global endpoint:
  - `https://<account-id>.r2.cloudflarestorage.com`
- region:
  - `auto`
- path style:
  - `false`

## 4. Create the Railway service

In Railway:

1. Create a new project
2. Add a service from this repo
3. Set the service root directory to `donut-sync`
4. Railway will use [railway.toml](/Users/benjamingouleau/Downloads/donutbrowser/donut-sync/railway.toml) and [Dockerfile](/Users/benjamingouleau/Downloads/donutbrowser/donut-sync/Dockerfile)
5. After the first deploy, copy the generated public HTTPS domain

## 5. Configure Railway environment variables

Set these on the Railway `donut-sync` service:

```bash
PORT=3929
S3_ENDPOINT=https://<account-id>.eu.r2.cloudflarestorage.com
S3_REGION=auto
S3_ACCESS_KEY_ID=<r2-access-key-id>
S3_SECRET_ACCESS_KEY=<r2-secret-access-key>
S3_BUCKET=twitterbrowser-sync
S3_FORCE_PATH_STYLE=false
SYNC_JWT_PUBLIC_KEY=-----BEGIN PUBLIC KEY-----...
SUPABASE_URL=https://errzkrimnulrgcjyiydb.supabase.co
SUPABASE_SERVICE_ROLE_KEY=<supabase-service-role-key>
```

After Railway redeploys, validate:

- `GET https://<railway-domain>/health`
- `GET https://<railway-domain>/readyz`

`readyz` must return `{"status":"ready","s3":true}`.

## 6. Point the desktop app to the public hosted sync URL

Set the public sync URL in local dev and in packaged app build env:

```bash
TWITTERBROWSER_SUPABASE_URL=https://errzkrimnulrgcjyiydb.supabase.co
TWITTERBROWSER_SUPABASE_ANON_KEY=<supabase-anon-key>
TWITTERBROWSER_SUPABASE_REDIRECT_URL=twitterbrowser://auth/callback
TWITTERBROWSER_CLOUD_SYNC_URL=https://<railway-domain>
```

For local development, put those in `.env.local`.

## 7. Verify hosted sync end to end

1. Launch TwitterBrowser with the public env
2. Sign in with:
   - email and password
   - email OTP
   - Google OAuth
3. Open Sync Configuration
4. Enable hosted sync explicitly
5. Confirm profile sync traffic hits the Railway domain instead of `127.0.0.1`
6. Confirm `cloud_profiles_used` changes in Supabase

## Google OAuth notes

The Google OAuth client should stay as a `Web application`.

Required Google redirect URI:

```text
https://errzkrimnulrgcjyiydb.supabase.co/auth/v1/callback
```

Required desktop redirect URL inside TwitterBrowser:

```text
twitterbrowser://auth/callback
```

If the Google OAuth consent screen is still in Testing mode, add your Google account as a test user before trying the desktop flow.
