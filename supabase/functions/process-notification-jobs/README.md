# process-notification-jobs

Supabase Edge Function worker that:
1. Claims pending rows from `notification_jobs`.
2. Resolves target tokens from `device_tokens`.
3. Sends notifications through Firebase Cloud Messaging.
4. Marks jobs as `sent` or `failed`.
5. Deactivates invalid tokens.

## Required Supabase Secrets

Set these in your Supabase project:

- `FIREBASE_PROJECT_ID`
- `FIREBASE_CLIENT_EMAIL`
- `FIREBASE_PRIVATE_KEY` (use literal key with newline chars escaped as `\n`)
- `PROCESS_QUEUE_SECRET` (optional but recommended for scheduler calls)

These are provided by Supabase automatically and are also used:

- `SUPABASE_URL`
- `SUPABASE_SERVICE_ROLE_KEY`

## Deploy

```bash
supabase functions deploy process-notification-jobs --no-verify-jwt
```

`--no-verify-jwt` is required because the Flutter admin panel sends a Firebase
ID token. Supabase cannot validate that token at the gateway, so the function
verifies it with Firebase Admin before processing jobs.

This function accepts either:
1. Firebase admin user ID token (validated against `users.isAdmin`), or
2. `x-process-queue-secret` header matching `PROCESS_QUEUE_SECRET` (for scheduler/backend).

## Invoke (manual)

From Flutter admin panel, use the Process Queue action.

Or call directly:

```bash
supabase functions invoke process-notification-jobs --body '{"limit":50}'
```

Scheduler/server call example with secret header:

```bash
curl -X POST "https://<PROJECT_REF>.functions.supabase.co/process-notification-jobs" \
	-H "Content-Type: application/json" \
	-H "x-process-queue-secret: <PROCESS_QUEUE_SECRET>" \
	-d '{"limit":50}'
```

## Scheduler (recommended)

Use Supabase scheduled jobs / cron to invoke this function every 1 minute so queued notifications are delivered automatically.
