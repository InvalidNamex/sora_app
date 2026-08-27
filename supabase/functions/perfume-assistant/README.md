# Vera perfume assistant

Authenticated, rate-limited perfume matching for the Flutter app.

## Required secrets

```bash
supabase secrets set DEEPINFRA_API_KEY=replace-me
supabase secrets set DEEPINFRA_MODEL=deepseek-ai/DeepSeek-V4-Flash
supabase secrets set TAVILY_API_KEY=replace-me
```

The Firebase and Supabase service-role secrets are the same ones used by the
other authenticated Edge Functions in this repository.

`VERA_ALLOWED_ORIGINS` is optional and accepts a comma-separated allowlist for
web deployments. Native Flutter requests do not send a browser Origin header.

## Data source

Vera first resolves a perfume against the Sora catalog, then against the
on-demand `perfume_reference_profiles` cache. A cache miss triggers a metered
Tavily search; DeepSeek extracts a strict evidence-only profile, which is
cached for 180 days. `VERA_SOURCE_DOMAINS` may optionally contain a
comma-separated search-domain allowlist. The function never fetches a URL
provided by the user.

The function never stores chat messages or perfume preferences. Only public
perfume facts, their source metadata, and non-content usage counters are
retained.

Deploy with Firebase gateway verification disabled because the function
verifies the Firebase ID token itself:

```bash
supabase functions deploy perfume-assistant --no-verify-jwt
```
