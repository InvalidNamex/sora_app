# Vera perfume assistant

Vera is Sora's authenticated Arabic/English perfume discovery assistant. It is
not a general-purpose chatbot.

## Product boundaries

- Firebase-authenticated users only.
- Friendly Egyptian Arabic or English, following the current message/app locale.
- Five catalog recommendations when available.
- Out-of-stock recommendations remain visible with a restock-soon message.
- Product detail and add-to-cart actions are returned as database IDs, never
  invented by the model.
- Chat messages and perfume preferences are held only in Flutter memory. They
  are not written to Supabase or device storage.
- Usage counters contain no chat text.

## Matching

DeepSeek extracts the supported intent and resolves perfume/brand/concentration
into strict JSON. The percentage is calculated by Sora code:

- 50% weighted accord cosine similarity
- 15% top-note Jaccard similarity
- 15% middle-note Jaccard similarity
- 20% base-note Jaccard similarity

Missing components are excluded and the remaining weights are normalized.
The model never generates a percentage.

## Limits

The production defaults live in `public.vera_config`:

- 10 requests/hour/user
- 30 requests/day/user
- 5-second cooldown
- one active request/user
- 500 characters/message
- 12 turns/session
- 500 configured output tokens
- global daily message and cost kill switches
- 30 on-demand web lookups/day globally by default
- 180-day freshness for Tavily-backed profiles

`consume_vera_quota` locks the singleton configuration row and the user's lease
row, making the checks atomic under concurrent requests.

## Reference data

The Sora catalog is always checked first. Unknown perfumes are checked in
`public.perfume_reference_profiles`, which acts as an on-demand cache. On a
cache miss, Vera uses Tavily to retrieve up to three sources and DeepSeek to
extract an evidence-only structured profile. Only public perfume facts and
source metadata are cached; raw page content is not stored.

FragDB's GitHub repository contains only 10-record samples. The full dataset is
commercially licensed. After obtaining the licensed CSV files:

```bash
SUPABASE_URL=https://project.supabase.co \
SUPABASE_SERVICE_ROLE_KEY=replace-me \
ruby tool/import_fragdb_profiles.rb \
  --fragrances /secure/path/fragrances.csv \
  --notes /secure/path/notes.csv \
  --accords /secure/path/accords.csv \
  --dry-run
```

Remove `--dry-run` only after reviewing the parsed count and confirming the
license. Never commit the dataset or service-role key.

## Deployment

1. Rotate any API credential that has appeared in chat, logs, or shell history.
2. Apply `20260827120000_vera_perfume_assistant.sql`.
3. Configure `DEEPINFRA_API_KEY` and optional `DEEPINFRA_MODEL` as Supabase
   secrets.
4. Deploy `perfume-assistant` with `--no-verify-jwt`; it validates Firebase ID
   tokens with Firebase Admin.
5. Configure `TAVILY_API_KEY`; optionally configure `VERA_SOURCE_DOMAINS`.
6. Apply `20260827170000_vera_online_lookup.sql`.
7. Schedule `cleanup_vera_operational_data()` daily.
8. Run the SQL, Deno, and Flutter test suites.

Do not deploy Vera with an exposed DeepInfra or Tavily key.
