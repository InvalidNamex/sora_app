# Sora Safe Next.js SEO Storefront Plan

## Decision

Build the Next.js storefront as a separate Git repository and a separate Vercel
project. Do not convert the Flutter repository and do not begin with complete
feature parity.

The first release is a read-only, server-rendered public catalog. Flutter remains
the source of truth for the mobile applications and all authenticated, checkout,
affiliate, and admin workflows.

This plan optimizes for four outcomes:

1. Product and category pages can be crawled and indexed in Arabic and English.
2. The existing Flutter project cannot be changed by Next.js work.
3. The existing production backend is not mutated during the SEO migration.
4. Production cutover is reversible without a code rollback or database rollback.

## Non-Negotiable Safety Boundaries

### Repository isolation

- Create a new private repository named `sora-web`.
- Do not place its Git history inside `/Volumes/Untitled/sora`.
- Treat the Flutter repository as read-only reference material.
- Never copy `.env`, signing files, Firebase native configuration, or secrets from
  the Flutter repository.
- Record any required Flutter change as a separate proposal. Do not make it from
  the web repository.

### Backend isolation

- Phase 1 may perform anonymous `SELECT` operations only.
- Use only the public Supabase URL and anonymous key in the browser/server build.
- Never provide the Next.js project with a Supabase service-role key.
- Do not add or edit database migrations, RLS policies, Storage policies, database
  functions, triggers, or Edge Functions.
- Do not implement cart, checkout, authentication, admin, affiliate payouts, or
  any other mutation in the SEO release.
- If an existing public read is unavailable under RLS, stop and document it. Do
  not weaken RLS to make the page work.

### Deployment isolation

- Use a new Vercel project with preview deployments enabled.
- Initially deploy only to the Vercel preview domain.
- Then validate on `new.sora-eg.store` or another staging subdomain.
- Keep `www.sora-eg.store` attached to the Flutter deployment until every release
  gate passes and the owner explicitly approves cutover.
- Keep the previous Flutter Vercel project deployed and ready for domain rollback.

### Production-data safety

- Automated tests must not create users, carts, orders, payouts, messages, or
  catalog records in production.
- Tests may use fixtures, mocked clients, or a separately approved test project.
- Product price and availability displayed by the website must come from the
  existing authoritative public read model.

## Target Architecture

```text
Search engine / visitor
          |
          v
Next.js public storefront (semantic HTML, read-only)
  /ar and /en
  product, category, bundle, contact, privacy pages
          |
          | anonymous reads permitted by existing RLS
          v
Existing Supabase project

Existing Flutter apps ----------------------> same existing backend
  mobile apps remain unchanged
  checkout/account/admin remain unchanged
```

After production cutover, public web URLs are owned by Next.js. Flutter mobile
applications continue to use the same backend. Web-only application functions
can remain on a separate Flutter hostname, such as `app.sora-eg.store`, if they
are still required in a browser.

## Phase 0: Freeze the Contract and Establish Recovery

No implementation begins until this phase is complete.

1. Record the currently deployed Flutter URL, Vercel project, production commit,
   environment variable names, DNS records, and domain configuration.
2. Confirm that the current Flutter deployment can be redeployed independently.
3. Export or document current Vercel redirects, headers, and rewrites.
4. Preserve:
   - `/.well-known/assetlinks.json`
   - `/.well-known/apple-app-site-association`
   - `/privacy_policy`
   - `/item/[id]`, `/bundle/[id]`, and `/ref/[code]` deep links
5. Inventory the exact anonymous Supabase tables, columns, joins, Storage URLs,
   and RLS behavior needed by the public catalog.
6. Capture representative fixture responses with secrets and personal data
   removed.
7. Define the one-step rollback: detach the domain from Next.js and reattach it
   to the still-running Flutter Vercel project.

Exit gate:

- The deployed Flutter version and DNS configuration are documented.
- A domain-only rollback is understood and does not require a database change.
- No backend modification is required for the public reads.

## Phase 1: Create the Independent Foundation

Create `sora-web` with:

- Next.js App Router
- TypeScript strict mode
- Server Components by default
- Tailwind CSS or scoped CSS using Sora design tokens
- `next-intl` for Arabic and English
- Zod at every database-response boundary
- Vitest for units and Playwright for browser checks
- Sentry configured without sensitive personal data

Initial route behavior:

- `/` redirects to `/ar`.
- Arabic routes use `lang="ar"` and `dir="rtl"`.
- English routes use `lang="en"` and `dir="ltr"`.
- Unknown locale and entity routes return real HTTP 404 responses.
- The site remains useful when JavaScript is disabled.

Exit gate:

- Lint, type checking, tests, and production build pass.
- The repository has no write-capable backend credential.
- A preview deployment succeeds without changing any production domain.

## Phase 2: Read-Only SEO Storefront

Implement only these public routes:

- `/[locale]`
- `/[locale]/catalog`
- `/[locale]/category/[id]`
- `/[locale]/item/[id]`
- `/[locale]/bundle/[id]`
- `/[locale]/contact`
- `/[locale]/privacy`

Each public page must render meaningful content in the initial HTTP response.
Client Components should be limited to optional interactions such as image
galleries, locale switching, filters, and share controls.

Product pages should render from the existing catalog model:

- localized name and description
- brand
- product images and meaningful alt text
- available sizes or variants
- authoritative price, discount, currency, stock, and availability
- fragrance notes, accords, sillage, and longevity where present
- category breadcrumbs and native HTML links

Do not add checkout or a write-capable cart in this phase. A call to action may
deep-link to an approved existing purchase experience, or remain informational
until the commerce phase is separately authorized.

Exit gate:

- There are zero database mutations in code and network tests.
- Every entity page returns 200 or a real 404 as appropriate.
- Public content is present in `view-source`, not only after hydration.
- Browser back/forward, keyboard navigation, RTL, and responsive layouts work.

## Phase 3: Technical SEO

Implement and verify:

- unique localized titles and descriptions
- self-referential canonical URLs
- reciprocal Arabic/English `hreflang` and `x-default`
- Open Graph and Twitter metadata with absolute image URLs
- `Organization` and `WebSite` JSON-LD on the homepage
- `Product` and `Offer` JSON-LD on product pages
- `BreadcrumbList` JSON-LD on category, product, and bundle pages
- generated `sitemap.xml`
- explicit `robots.txt`
- stable image dimensions and optimized image delivery
- correct 200, 301/308, 404, and 410 behavior
- `noindex` for internal search/filter combinations that should not rank

Structured data must reflect visible content. Price and availability must not be
invented or allowed to become materially stale.

Exit gate:

- Built HTML contains the metadata and JSON-LD.
- Sitemap URLs all resolve successfully and use canonical production shapes.
- Rich Results validation passes for representative products.
- Lighthouse is run on Arabic and English home, category, and product pages.
- There are no hydration errors or layout shifts caused by server/client content
  disagreement.

## Phase 4: Legacy Links and Mobile-App Associations

Before moving the domain, implement permanent redirects:

- `/home` -> `/ar`
- `/catalog` -> `/ar/catalog`
- `/item/[id]` -> `/ar/item/[id]`
- `/bundle/[id]` -> `/ar/bundle/[id]`
- `/privacy_policy` -> `/ar/privacy`

Handle `/ref/[code]` without losing attribution. Its final behavior must be
approved before cutover because it affects the affiliate program.

Serve the existing Android and Apple association documents with the correct
content type. Verify that their application identifiers and path coverage remain
unchanged. Do not casually redirect these files.

Exit gate:

- Historical URLs have automated redirect tests.
- Installed Android and iOS applications still receive approved deep links in a
  staging-domain test or documented production-safe validation.
- Social-sharing previews work for representative product URLs.

## Phase 5: Preview and Staging Validation

Deploy to the Vercel preview domain, then the staging subdomain.

Validation matrix:

- Arabic and English
- mobile, tablet, and desktop
- Chromium, WebKit, and a real mobile browser
- JavaScript enabled and disabled for public routes
- valid, missing, out-of-stock, discounted, and malformed product records
- slow backend response and backend failure
- direct URL entry, refresh, back/forward, and shared links
- crawler-visible HTML, metadata, canonical, hreflang, JSON-LD, robots, sitemap
- `assetlinks.json` and `apple-app-site-association`

Required automated commands:

```bash
npm run lint
npm run typecheck
npm run test
npm run build
npm run test:e2e
```

Required operational review:

- Confirm logs contain no keys, tokens, phone numbers, addresses, or user data.
- Confirm the deployment has no service-role secret.
- Confirm no production table receives writes during the test window.
- Confirm Flutter Android and iOS builds are unaffected.

Exit gate:

- All automated and manual checks are recorded in a release checklist.
- The owner approves the exact production deployment artifact.
- The rollback owner and rollback steps are confirmed.

## Phase 6: Controlled Production Cutover

1. Deploy the approved immutable commit to the Next.js production project.
2. Smoke-test it on its Vercel production URL.
3. Lower DNS TTL in advance if DNS changes are involved.
4. Attach `www.sora-eg.store` to Next.js during a low-traffic window.
5. Do not delete or modify the Flutter deployment.
6. Verify home, representative products, redirects, sitemap, robots, association
   files, TLS, analytics, errors, and mobile deep links.
7. Monitor HTTP 4xx/5xx rates, server errors, backend latency, and crawler access.

Immediate rollback triggers:

- product pages fail or return incorrect prices
- widespread 404/500 responses
- broken Android or iOS deep links
- exposed secrets or personal data
- unexpected database writes
- severe performance regression

Rollback consists of returning the domain to the existing Flutter project. No
database rollback should be necessary because the SEO release is read-only.

## Post-Cutover Observation

For the first two weeks:

- inspect Vercel and Sentry errors daily
- inspect Google Search Console indexing and sitemap processing
- inspect canonical and alternate-language selection
- monitor missing routes and redirect loops
- compare catalog price/availability with the authoritative backend
- retain the Flutter deployment and rollback instructions

Do not interpret indexing as guaranteed ranking. Technical SEO only makes the
content eligible and understandable; content quality, competition, authority,
and merchant signals still determine results.

## Later Commerce Migration: Separate Approval Required

The following are explicitly outside the SEO storefront release:

- Firebase authentication
- authenticated Supabase client
- guest or synchronized carts
- checkout and order placement
- addresses and account pages
- wishlist and reviews
- affiliate dashboard and payouts
- admin workflows
- notifications

Each capability requires its own threat model, test environment, backend-contract
review, preview validation, and rollback plan. None should be added merely to
claim complete Next.js parity.

A sensible later order is:

1. local guest cart with no backend writes
2. authentication in preview
3. authenticated read-only account pages
4. cart synchronization against a test backend
5. checkout against a test backend with idempotency
6. production commerce after a dedicated release review
7. admin last, preferably as a separately protected application

## Definition of Done for the SEO Migration

The migration is complete when:

- Next.js lives in an independent repository and deployment project.
- No Flutter source, mobile configuration, migration, Edge Function, or RLS policy
  was changed for the SEO release.
- Public pages return semantic Arabic/English HTML and correct HTTP statuses.
- Metadata, canonicals, hreflang, structured data, sitemap, and robots are valid.
- Legacy links and mobile association files continue to work.
- The production release contains no backend write path or privileged credential.
- Automated, accessibility, SEO, performance, and deep-link gates pass.
- Domain cutover and rollback are documented and rehearsed.
- The Flutter deployment remains available until the observation period ends and
  its retirement is separately approved.

