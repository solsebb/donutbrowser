# TwitterBrowser Sync Service

`donut-sync` is the hosted and self-hosted sync API used by TwitterBrowser.

## Responsibilities

- Validate sync credentials
- Store profile payloads in S3-compatible object storage
- Issue presigned upload and download URLs
- Report hosted profile usage back to Supabase

## Supported modes

### Self-hosted mode

Use a shared token:

```bash
SYNC_TOKEN=replace-me
```

### Hosted mode

Use the Supabase-backed hosted flow:

```bash
SYNC_JWT_PUBLIC_KEY="-----BEGIN PUBLIC KEY-----..."
SUPABASE_URL=https://<project-ref>.supabase.co
SUPABASE_SERVICE_ROLE_KEY=...
```

The matching private key must live in the Supabase project as the `SYNC_JWT_PRIVATE_KEY` secret for the `issue-sync-token` Edge Function.

## Local development

Start local MinIO:

```bash
docker compose up -d minio
```

Run the service:

```bash
pnpm install
pnpm start:dev
```

Health checks:

- `GET /health`
- `GET /readyz`

## Public deployment

The recommended hosted deployment for this repo is:

- Railway for the public HTTPS service
- Cloudflare R2 for S3-compatible object storage
- Supabase for auth, account metadata, and hosted sync JWT issuance

Use these repo files when deploying:

- [railway.toml](/Users/benjamingouleau/Downloads/donutbrowser/donut-sync/railway.toml)
- [Dockerfile](/Users/benjamingouleau/Downloads/donutbrowser/donut-sync/Dockerfile)
- [.env.example](/Users/benjamingouleau/Downloads/donutbrowser/donut-sync/.env.example)
- [docs/hosted-sync-railway-r2.md](/Users/benjamingouleau/Downloads/donutbrowser/docs/hosted-sync-railway-r2.md)

## Required runtime environment

```bash
PORT=3929
S3_ENDPOINT=
S3_REGION=
S3_ACCESS_KEY_ID=
S3_SECRET_ACCESS_KEY=
S3_BUCKET=
S3_FORCE_PATH_STYLE=
SYNC_JWT_PUBLIC_KEY=
SUPABASE_URL=
SUPABASE_SERVICE_ROLE_KEY=
```
