# Sora Next.js Migration Plan

## Objective

Rebuild the Sora Flutter Web storefront as a standalone, web-first Next.js application with semantic HTML, native browser behavior, server-rendered public pages, and strong Arabic/English SEO.

The Next.js website will eventually replace Flutter Web at `https://www.sora-eg.store`, while the Flutter Android and iOS applications continue using the same Firebase, Supabase, database, and Edge Function backend.

## Non-Negotiable Repository Boundary

- All new implementation changes must remain inside `/Volumes/Untitled/sora/nextjs`.
- Do not edit, move, delete, or reformat existing Flutter, platform, Supabase, database, or legacy `web/` files.
- Existing files outside `nextjs/` may be read as behavioral and data-contract references only.
- The repository already contains unrelated uncommitted Flutter changes. Do not revert or modify them.
- Do not add database migrations or rewrite Edge Functions during the initial migration.
- Do not expose or commit credentials. Only public browser configuration may use `NEXT_PUBLIC_*` variables.

## Confirmed Product Decisions

- Scope: complete feature parity, including customer, affiliate, and admin workflows.
- Design: web-first redesign that preserves Sora branding rather than translating Flutter widgets literally.
- Locales: Arabic and English with canonical `/ar` and `/en` URL prefixes.
- Default locale: Arabic. `/` redirects to `/ar`.
- Backend: reuse the existing live Firebase project, Supabase database, RLS policies, Storage, and Edge Functions.
- Deployment: validate on a Vercel preview before replacing Flutter Web on the main domain.
- Catalog URLs: keep stable numeric IDs. Do not require slug or SEO-column database migrations.
- State ownership:
  - Server Components: public SEO content and initial catalog reads.
  - TanStack Query: authenticated or interactive remote data, mutations, caching, and refetching.
  - Zustand: small local or persisted state such as guest cart, theme, and affiliate attribution.
  - Never duplicate TanStack Query data in Zustand.
- Styling: Tailwind CSS and project CSS tokens.
- shadcn/ui: optional and selective for accessible dialogs, menus, sheets, forms, and data tables. Restyle every primitive to the Sora system; do not use stock shadcn page design.

## Technology Stack

- Next.js 16 App Router
- React 19
- TypeScript with strict checking
- Tailwind CSS 4
- `next-intl`
- Firebase Web SDK
- `@supabase/supabase-js`
- TanStack Query
- Zustand with persisted stores
- Zod
- React Hook Form
- Embla Carousel
- Lucide icons
- React Leaflet for location selection
- Sentry for Next.js
- Vitest and Testing Library
- Playwright

## Current Implementation Status

The initial foundation has already been implemented inside `nextjs/`.

### Completed

- Next.js App Router scaffold with TypeScript, Tailwind, ESLint, `src/`, and npm.
- Arabic and English locale routing using `/ar` and `/en`.
- `/` redirects to `/ar`.
- Arabic RTL and English LTR document direction.
- Localized messages and navigation.
- Sora-owned logos, placeholder image, and ElMessiri/Kufi fonts copied into `nextjs/public`.
- Web-first responsive header, footer, hero, category rail, and product grid.
- Server-only anonymous Supabase client using existing `SUPABASE_URL` and `SUPABASE_ANON_KEY` variables.
- Defensive Zod parsing for items, properties, categories, and banners.
- Real public Supabase catalog reads.
- Server-rendered routes:
  - `/[locale]`
  - `/[locale]/item/[id]`
  - `/[locale]/category/[id]`
  - `/[locale]/search`
  - `/[locale]/contact`
  - `/[locale]/privacy`
- Persistent guest cart using Zustand.
- Product variant selection and add-to-cart interaction.
- Functional localized cart route.
- Product metadata, canonical URLs, reciprocal hreflang, Open Graph data, and Product JSON-LD.
- Dynamic sitemap, robots rules, and web manifest.
- Existing English privacy policy wording preserved. Arabic legal translation has not been invented.
- Development server configured and previously verified at `http://localhost:3000`.

### Verified

- `npm run lint`
- `npx tsc --noEmit`
- `npm run build`
- `/` returns a redirect to `/ar`.
- `/ar` and `/en` return HTTP 200.
- A real product route such as `/ar/item/1` returns HTTP 200.
- Product HTML contains `application/ld+json` structured data.
- Existing code outside `nextjs/` was not modified by this migration work.

### Important Existing Paths

- `src/app/[locale]/layout.tsx`: locale shell, providers, metadata, header, and footer.
- `src/app/[locale]/page.tsx`: server-rendered homepage.
- `src/app/[locale]/item/[id]/page.tsx`: product detail, metadata, and JSON-LD.
- `src/app/[locale]/category/[id]/page.tsx`: category listing.
- `src/app/[locale]/search/page.tsx`: catalog search.
- `src/app/[locale]/cart/page.tsx`: guest cart page.
- `src/lib/catalog.ts`: public Supabase catalog queries.
- `src/lib/supabase/public.ts`: server-only public Supabase client.
- `src/types/catalog.ts`: Zod schemas and catalog types.
- `src/stores/cart-store.ts`: persisted guest cart state.
- `src/messages/ar.json` and `src/messages/en.json`: localized messages.
- `src/app/globals.css`: Sora design tokens and responsive styling.

## Architecture

### Public Server-Rendered Pages

Use Server Components for content search engines and unauthenticated visitors must receive in the initial HTML:

- Homepage
- Category listings
- Product details
- Bundle details
- Contact
- Privacy policy

Use short revalidation for stock and price-sensitive pages. Use longer caching for category and legal content. Do not query nonexistent `created_at` or `updated_at` columns.

### Browser-Side Functionality

Use Client Components only where browser APIs or interaction require them:

- Firebase authentication
- Phone OTP and reCAPTCHA
- Google sign-in popup
- Guest cart persistence
- Product variant selection
- Cart controls
- Wishlist interactions
- Theme preference
- Affiliate link capture
- Notification permission and FCM registration
- Interactive filters
- Maps and geolocation

Keep client islands small. Do not turn public pages into fully client-rendered applications.

### Supabase Clients

Maintain distinct clients:

1. Server-only anonymous client for public catalog SSR/ISR reads.
2. Browser client for authenticated RLS queries. Its access-token callback must obtain the current Firebase ID token.
3. Server/admin code must never bundle service-role credentials into browser JavaScript.

Existing RLS and Edge Functions remain the authorization boundary. Client route guards are navigation UX only.

### Error and Empty-State Policy

- Parse all database responses defensively with Zod.
- Never assume nullable database values exist.
- Skip malformed catalog rows rather than crashing an entire listing.
- Render useful empty, loading, retry, not-found, and error states.
- Send operational exceptions to Sentry without sensitive personal data.
- Only clear carts or optimistic state after authoritative backend success.

## Route Plan

### Public and Guest Routes

- `/[locale]`
- `/[locale]/item/[id]`
- `/[locale]/category/[id]`
- `/[locale]/bundle/[id]`
- `/[locale]/search`
- `/[locale]/contact`
- `/[locale]/privacy`
- `/[locale]/auth`
- `/[locale]/cart`
- `/[locale]/ref/[code]`

### Authenticated Customer Routes

- `/[locale]/checkout`
- `/[locale]/account`
- `/[locale]/account/addresses`
- `/[locale]/account/wishlist`
- `/[locale]/account/orders`
- `/[locale]/account/orders/[id]`
- `/[locale]/account/orders/[id]/review`
- `/[locale]/account/delete`
- `/[locale]/location-picker`

### Affiliate Route

- `/[locale]/affiliate`

### Admin Routes

- `/[locale]/admin`
- `/[locale]/admin/orders`
- `/[locale]/admin/affiliates`
- `/[locale]/admin/catalog`
- `/[locale]/admin/bundles`
- `/[locale]/admin/reports`
- `/[locale]/admin/video-ads`
- `/[locale]/admin/notifications`
- `/[locale]/admin/item-suggestions`
- `/[locale]/admin/feedback`

### Legacy Compatibility

Preserve incoming mobile and historical links with redirects:

- `/home` to `/ar`
- `/item/[id]` to `/ar/item/[id]`
- `/bundle/[id]` to `/ar/bundle/[id]`
- `/ref/[code]` to `/ar/ref/[code]`
- `/orders/[id]` to the localized protected order route
- `/privacy_policy` to `/ar/privacy`

Preserve the Android and Apple association files when deployment work begins.

## Implementation Phases

### Phase 1: Complete Shared Foundation

1. Add a browser Firebase initializer with environment validation.
2. Add the authenticated browser Supabase client using Firebase ID tokens.
3. Add a single auth provider based on `onAuthStateChanged`.
4. Add role-aware route-gate utilities for customer, affiliate, and admin routes.
5. Add validated `next` URL handling so protected-route attempts resume after authentication.
6. Add a reusable Query Client policy for retries, stale times, errors, and mutation invalidation.
7. Add shared components for forms, dialogs, sheets, tables, pagination, toasts, skeletons, error boundaries, and empty states.
8. Initialize only the shadcn primitives actually required by those components.

Completion criteria:

- No duplicate Firebase or Supabase client instances.
- Auth listeners clean up correctly.
- Server Components do not import browser SDK modules.
- All environment errors provide actionable development messages.

### Phase 2: Authentication and User Synchronization

1. Rebuild Google sign-in using the Firebase Web SDK popup flow.
2. Rebuild phone OTP with web reCAPTCHA lifecycle handling.
3. Synchronize authenticated Firebase users to the Supabase `users` table using the existing backend contract.
4. Load the current Supabase user profile and role flags.
5. Implement logout and pending-route restoration.
6. Add accessible loading, validation, retry, and provider-error UI.
7. Ensure Arabic and English auth forms are fully localized.

Reference files outside `nextjs/`:

- `lib/app/modules/auth/auth_controller.dart`
- `mds/authentication.md`
- `lib/firebase_options.dart`
- `supabase/functions/sync-auth-claims/`

Completion criteria:

- Google and phone authentication work in preview and production domains.
- RLS-authenticated Supabase reads receive the Firebase ID token.
- Failed login does not lose guest cart or affiliate attribution.

### Phase 3: Cart Synchronization and Checkout

1. Preserve the existing guest cart in Zustand/localStorage.
2. On login, merge guest lines into the Supabase cart by property ID.
3. Handle duplicates by increasing quantity rather than creating duplicate variants.
4. Clear local guest state only after every remote upsert succeeds.
5. Implement bundle cart parity.
6. Build address selection and default-address behavior.
7. Build promo and affiliate code validation through the existing Edge Function.
8. Enforce non-stacking discounts.
9. Keep cash on delivery as the only payment method.
10. Submit orders through the existing secure order-placement Edge Function.
11. Treat server totals as authoritative.
12. Add submission idempotency and prevent double-click duplicate orders.
13. Clear cart only after confirmed order success.

Reference files:

- `lib/app/modules/cart/cart_controller.dart`
- `lib/app/modules/checkout/checkout_controller.dart`
- `lib/app/core/services/affiliate_program_service.dart`
- `supabase/functions/affiliate-program/`

Completion criteria:

- Guests can browse and use the cart.
- Checkout forces authentication and then restores checkout.
- Promo, affiliate, total, and cart-clearing behavior matches Flutter.
- Automated tests never place a real production order.

### Phase 4: Customer Account Parity

1. Build profile with avatar, name, phone, role links, locale, theme, and logout.
2. Build address CRUD, default selection, and validation.
3. Build map-based location selection using React Leaflet/OpenStreetMap.
4. Build authenticated wishlist.
5. Build order history with status badges.
6. Build order detail with itemized pricing and delivery information.
7. Build delivered-order feedback and per-item ratings.
8. Build account deletion using the existing anonymizing Edge Function.
9. Restore theme persistence with accessible dark/light controls.

Reference files:

- `lib/app/modules/profile/`
- `lib/app/modules/address_book/`
- `lib/app/modules/wishlist/`
- `lib/app/modules/history/`
- `lib/app/core/services/order_feedback_service.dart`
- `lib/app/core/services/account_deletion_service.dart`

Completion criteria:

- RLS restricts every customer query to the authenticated user.
- Review submission is available only for eligible delivered orders.
- Account deletion requires explicit confirmation and handles reauthentication errors.

### Phase 5: Catalog, Bundles, and Storefront Completion

1. Add homepage banner and video-ad carousel using Embla and native video.
2. Add active bundles to home and bundle detail routes.
3. Add URL-backed category, subcategory, gender, stock, sort, and search filters.
4. Preserve browser back/forward behavior and shareable filter URLs.
5. Add fragrance metadata: notes pyramid, accords, sillage, and longevity.
6. Add wishlist and share controls to product pages.
7. Add accessible image galleries and fallbacks.
8. Add robust unavailable-property behavior.
9. Add responsive loading skeletons without layout shift.

Reference files:

- `lib/app/modules/home/`
- `lib/app/modules/item/`
- `lib/app/modules/bundle_detail/`
- `lib/app/core/models/item_model.dart`
- `lib/app/core/models/bundle_deal_model.dart`

Completion criteria:

- Public content remains readable without JavaScript.
- Filters are represented in the URL.
- Product cards and fixed-format media do not resize unexpectedly.
- Out-of-stock products and variants cannot be added.

### Phase 6: Affiliate Program

1. Capture `/ref/[code]` attribution and persist code/source for 30 days.
2. Synchronize pending attribution after login.
3. Prevent affiliates from using their own code.
4. Build affiliate profile and editable public code behavior.
5. Display total, pending, and available earnings.
6. Display commission-generating orders and payout history.
7. Generate copyable/shareable localized links.
8. Submit payout requests without accepting a client-calculated amount.

Reference files:

- `lib/app/modules/affiliate/`
- `lib/app/core/services/affiliate_program_service.dart`
- `mds/affiliate-program.md`
- `supabase/migrations/20260718120000_affiliate_program.sql`

Completion criteria:

- Code format and self-referral rules match the backend.
- Server responses determine earnings and payout availability.
- Attribution survives locale changes, auth, and page reloads.

### Phase 7: Admin Feature Parity

Build a dense, work-focused admin interface with a responsive sidebar, tables, filters, pagination, dialogs, and explicit mutation feedback.

Sections:

1. Dashboard metrics.
2. Orders and status transitions.
3. Affiliate applications and payouts.
4. Catalog, categories, products, properties, and image uploads.
5. Bundle management.
6. Reports.
7. Video ads.
8. Notification campaigns.
9. Item suggestions.
10. Customer feedback.

Rules:

- Enforce admin role in both UI navigation and backend contract.
- Never trust the client role check as authorization.
- Use TanStack Query mutations and invalidate affected queries.
- Use optimistic updates only where deterministic rollback is possible.
- Refetch authoritative results after privileged mutations.

Reference files:

- `lib/app/modules/admin/`
- `admin_dashboard.md`
- `supabase/functions/manage-bundles/`
- `supabase/functions/manage-in-app-messages/`

Completion criteria:

- Every existing Flutter admin route has a functional web equivalent.
- Unauthorized users cannot load or mutate admin data.
- Tables remain usable on narrow screens without overlapping text.

### Phase 8: Notifications and Deep Links

1. Add a public Firebase Messaging service worker.
2. Request notification permission only after explicit user intent.
3. Register and rotate FCM web tokens.
4. Handle foreground notifications.
5. Route notification clicks to localized product, order, and affiliate pages.
6. Render in-app card, banner, and modal messages after initial catalog render.
7. Preserve Universal Link and Android App Link files at deployment.

Reference files:

- `lib/app/core/services/notification_service.dart`
- `lib/app/core/services/deep_link_service.dart`
- `lib/app/core/services/in_app_messaging_service.dart`
- `mds/notifications.md`
- `mds/deep-linking.md`
- `web/.well-known/`

Completion criteria:

- Unsupported browsers degrade gracefully.
- Notification denial does not block shopping.
- Deep links preserve locale and restore protected routes after auth.

### Phase 9: SEO Completion

1. Add bundle metadata and valid structured data.
2. Add Organization and WebSite JSON-LD to the homepage.
3. Add BreadcrumbList JSON-LD to category, item, and bundle pages.
4. Validate unique localized titles and descriptions.
5. Keep self-referential canonicals and reciprocal `ar`/`en` hreflang links.
6. Point `x-default` to Arabic.
7. Ensure auth, cart, checkout, account, affiliate, and admin routes are `noindex`.
8. Keep search pages `noindex, follow`.
9. Validate sitemap coverage and robots exclusions.
10. Add social image fallbacks and product price/availability metadata where valid.
11. Add meaningful image alt text.
12. Do not invent SEO fields or use nonexistent timestamps.

Completion criteria:

- Verify metadata from built HTML, not only hydrated DOM.
- Structured data passes Google Rich Results testing where applicable.
- Every public route returns correct 200, 404, or redirect status.

### Phase 10: Testing, Accessibility, and Deployment

#### Automated checks

Run after every meaningful phase:

```bash
npm run lint
npx tsc --noEmit
npm run build
```

Add:

- Zod parser unit tests.
- Cart reducer/store tests.
- Auth and guest-cart synchronization tests.
- Edge Function response parsing tests.
- Component accessibility tests.
- Playwright tests on Chromium and WebKit.

#### Playwright matrix

Test Arabic RTL and English LTR at:

- Mobile
- Tablet
- Desktop

Cover:

- Locale navigation
- Back/forward browser history
- Search and URL filters
- Product variant selection
- Guest cart persistence
- Login restoration
- Address and checkout
- Order history and feedback
- Affiliate role and payout request
- Every admin section
- Keyboard-only operation
- Dialog focus trapping
- Mobile layout overlap

#### Performance and accessibility

Run Lighthouse or equivalent on:

- Home
- Category
- Product
- Cart
- Checkout

Check:

- Core Web Vitals
- Layout shift
- Mobile tap targets
- Visible focus
- Heading hierarchy
- Form labels and errors
- Color contrast
- Reduced-motion behavior
- JavaScript-disabled readability for public pages

#### Deployment

1. Configure Vercel project root as `nextjs`.
2. Configure preview and production environment variables.
3. Configure allowed remote image hosts for Supabase Storage.
4. Add security and cache headers.
5. Test Firebase authorized domains for preview and production.
6. Test Google and phone auth on the preview domain.
7. Test Universal Links and Android App Links.
8. Validate checkout without creating unintended production orders.
9. Only after complete validation, point `www.sora-eg.store` to Next.js.
10. Keep Flutter mobile apps and backend operational throughout cutover.

## Environment Variables

Do not store values in this plan. Use `.env.example` as the source of required names.

Expected categories:

- App base URL
- Supabase URL and anonymous key
- Firebase browser configuration
- Firebase Messaging VAPID key
- Sentry public DSN

Server-only credentials must never use a `NEXT_PUBLIC_` prefix.

## Source-of-Truth References

Read these existing files without modifying them:

### Routes and behavior

- `../lib/app/routes/app_pages.dart`
- `../lib/app/routes/app_routes.dart`
- `../lib/app/core/middleware/route_guards.dart`
- `../lib/app/global_widgets/app_scaffold.dart`
- `../lib/app/global_widgets/app_drawer.dart`

### Core commerce

- `../lib/app/modules/home/home_controller.dart`
- `../lib/app/modules/item/item_controller.dart`
- `../lib/app/modules/cart/cart_controller.dart`
- `../lib/app/modules/checkout/checkout_controller.dart`

### Backend contracts

- `../lib/app/core/services/supabase_service.dart`
- `../lib/app/core/services/affiliate_program_service.dart`
- `../lib/app/core/services/deep_link_service.dart`
- `../lib/app/core/services/notification_service.dart`
- `../lib/app/core/services/order_feedback_service.dart`
- `../lib/app/core/services/account_deletion_service.dart`
- `../supabase/functions/`
- `../supabase/migrations/`

### Models and translations

- `../lib/app/core/models/`
- `../lib/app/translations/app_translations.dart`
- `../lib/app/core/constants/app_constants.dart`
- `../lib/app/core/theme/app_theme.dart`

### Documentation

- `../instructions.md`
- `../FEATURE_BUILD_GUIDE.md`
- `../mds/authentication.md`
- `../mds/affiliate-program.md`
- `../mds/notifications.md`
- `../mds/deep-linking.md`
- `../web/privacy_policy/index.html`
- `../web/.well-known/`

## Final Definition of Done

The migration is complete only when:

- Every current customer, affiliate, and admin workflow has a working Next.js equivalent.
- Public pages are server-rendered and indexable in Arabic and English.
- Authentication, RLS, cart synchronization, checkout, affiliate accounting, and admin authorization use existing backend contracts correctly.
- Legacy product, bundle, affiliate, order, and privacy links redirect correctly.
- Mobile and desktop layouts have no overlap or overflow.
- Public pages remain meaningful without JavaScript.
- Lint, TypeScript, production build, unit tests, Playwright tests, accessibility checks, and SEO validation pass.
- Preview-domain auth, messaging, deep links, and checkout are verified.
- No existing source file outside `nextjs/` was modified by the migration.
- Main-domain cutover occurs only after the preview deployment passes the complete verification matrix.
