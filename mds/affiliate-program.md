# Affiliate Program Implementation Guide

Use this file as the source of truth for Sora's affiliate program.

## Final Business Rules

- Every affiliate has one public, customizable affiliate code.
- Codes contain 4-20 uppercase ASCII letters or numbers.
- Codes are case-insensitively unique.
- Customer discount and affiliate commission percentages are controlled by an
  administrator in the database.
- Default customer discount: 10%.
- Default affiliate commission: 15%.
- Commission is calculated from the merchandise total after the customer
  discount.
- Delivery fees are not included in the commission basis.
- A product share link uses:

```text
https://www.sora-eg.store/item/<item_id>?ref=<affiliate_code>
```

- A general affiliate link uses:

```text
https://www.sora-eg.store/ref/<affiliate_code>
```

- Opening either link saves the code locally.
- If the visitor is logged in, the attribution is also persisted in Supabase.
- A local link attribution is synchronized after login.
- Checkout loads persisted attribution from Supabase when local storage is
  empty, supporting another device.
- Manually entering an affiliate code is equivalent to following an affiliate
  link.
- A manually entered code overrides a saved link code for that checkout.
- Affiliate codes do not stack with vouchers or promotions.
- Affiliates cannot use their own code.
- An affiliate attribution expires after 30 days.
- The attribution is consumed when an affiliate order is placed.
- The order permanently snapshots its code, source, discount, commission rate,
  and commission amount.
- Commission is pending until the order is delivered.
- Delivered orders make commission available for payout.
- Cancelled or returned unpaid orders void the commission.
- Admins mark payouts paid only after completing the external transfer and
  recording its payment reference.
- Rejected payouts return their attached commission rows to available.

Example:

```text
Merchandise subtotal:       EGP 1,000
Customer discount (10%):    EGP   100
Customer total:             EGP   900
Affiliate commission (15%): EGP   135
```

## Do Not Reintroduce

- Do not expose or share the Firebase UID as an affiliate identifier.
- Do not store `active_affiliate_id`.
- Do not calculate affiliate earnings from the current
  `item_properties.affiliatePercentage`.
- Do not let Flutter insert order totals, affiliate IDs, or commission amounts.
- Do not let an affiliate submit an arbitrary payout amount.
- Do not calculate historical commissions dynamically from mutable settings.
- Do not permit direct client access to affiliate ledger tables.

## Flutter Components

### AffiliateProgramService

Path:

```text
lib/app/core/services/affiliate_program_service.dart
```

Responsibilities:

- Normalize codes to uppercase.
- Persist local link/manual attribution.
- Synchronize link attribution after Firebase login.
- Validate affiliate, voucher, and promotion codes.
- Retrieve remote attribution for cross-device checkout.
- Place orders through the Edge Function.
- Load affiliate dashboard data.
- Update the current affiliate's code.
- Request payout through the server.
- Submit and inspect affiliate applications through the server.

Storage keys:

```text
active_affiliate_code
active_affiliate_source
```

Allowed source values:

```text
link
manual
```

### Deep Links

`DeepLinkService` reads `ref` from item links or the segment from `/ref/CODE`
and calls:

```dart
AffiliateProgramService.captureLinkCode(code, itemId: itemId);
```

The app navigates to the item or home after capture. Invalid code formats are
ignored. Code validity and affiliate status are verified server-side.

The checkout promo field accepts a plain code, a shared item URL, a referral
URL, or the complete share message. Extract and normalize `ref` before server
validation:

```text
TEST26
https://www.sora-eg.store/item/42?ref=TEST26
https://www.sora-eg.store/ref/TEST26
```

### Item Sharing

`ShareService.itemLink` uses the public code:

```dart
ShareService.itemLink(itemId, affiliateCode: code);
```

Regular users share the item URL without `ref`. Logged-in affiliates retrieve
their current code from the backend and append it to the item URL.

### Authentication

After Firebase login or cold-start restoration:

```dart
unawaited(AffiliateProgramService.syncPendingAttribution());
```

Sign-out clears only the in-memory affiliate profile cache. A customer's
unconverted local attribution remains available unless explicitly consumed or
invalidated.

### Checkout

Checkout never writes `order_master` or `order_detail` directly.

Flow:

1. Load local affiliate code.
2. If local code is absent, load the user's active server attribution.
3. Validate the displayed promo code using the Edge Function.
4. Show the preview discount.
5. On Place Order, send only address ID, phone, notes, code, and source.
6. The backend reloads cart prices and calculates authoritative totals.
7. Clear the local cart state after backend success.
8. Clear consumed affiliate attribution.

The backend remains authoritative even if the preview differs because a price
changed between validation and order placement.

### Affiliate Dashboard

The dashboard:

- Shows the editable public code.
- Shows read-only customer discount and affiliate commission percentages.
- Shows total earnings, pending earnings, and available balance.
- Shows frozen commission amounts per referred order.
- Requests all available balance through the server.

Affiliates cannot edit their own percentages.

### Affiliate Applications

Non-affiliate users see **Become an Affiliate** in Profile. Submission requires:

```text
preferredCode: 4-20 ASCII letters or numbers
message: 10-500 characters
```

Only one pending application per user is allowed. Pending preferred codes are
also unique. Admin review is transactional:

- Approval sets `users.isAffiliate = true`.
- The affiliate-code trigger provisions the row.
- The requested code replaces the generated default code.
- Rejection leaves the user unchanged and can include an admin note.
- Both submission and review enqueue targeted notifications.

Do not let the client update `users.isAffiliate` to approve an application.

### Payout Handling

Only commission rows in `available` state can enter a payout. The affiliate
chooses one destination:

```text
mobile_wallet
instapay
bank_transfer
```

The server calculates the full available balance; the affiliate cannot submit
an arbitrary amount. Creating a request moves the attached commission rows to
`processing`.

There is intentionally no automatic money transfer integration. The admin:

1. Transfers the displayed amount to the stored payout destination.
2. Enters the provider/bank transaction reference.
3. Selects **Mark Paid**.

The secure review RPC then marks the payout `Paid` and its exact commission rows
`paid`. Rejection returns those rows to `available`. Never mark a request paid
before the external transfer succeeds.

## Database Contract

Migrations:

```text
supabase/migrations/20260718120000_affiliate_program.sql
supabase/migrations/20260719010000_affiliate_code_provisioning.sql
supabase/migrations/20260719030000_affiliate_workflows_and_admin_notifications.sql
```

### affiliate_codes

Important columns:

```text
affiliateID
code
customerDiscountPercentage
affiliateCommissionPercentage
isActive
createdAt
updatedAt
```

Existing affiliates receive `SORA<users.id>` during migration. Enabling a user
as an affiliate creates or reactivates their code. Disabling an affiliate
deactivates their code. Provision on both user insertion and `isAffiliate`
updates, then backfill active affiliates. Handling only updates leaves imported
users that were inserted with `isAffiliate = true` without a code.

To set percentages manually:

```sql
update public.affiliate_codes
set
  "customerDiscountPercentage" = 10,
  "affiliateCommissionPercentage" = 15,
  "updatedAt" = now()
where upper(code) = 'RIOS10';
```

### customer_affiliate_attributions

Stores active and consumed attribution:

```text
userID
affiliateCodeID
source
itemID
attributedAt
expiresAt
convertedOrderID
isActive
```

Only one active attribution is allowed per user.

### affiliate_commissions

This is the financial ledger:

```text
affiliateID
orderID
affiliateCodeID
source
eligibleSubtotal
customerDiscountAmount
commissionPercentage
amount
status
payoutRequestID
createdAt
availableAt
paidAt
```

Status values:

```text
pending
available
processing
paid
void
```

Never derive balances from current catalog or code percentages.

### order_master Snapshots

Affiliate orders snapshot:

```text
affiliateID
affiliateCodeID
affiliateCode
affiliateSource
affiliateDiscountPercentage
affiliateCommissionPercentage
affiliateCommissionAmount
appliedPromoCode
promoType
```

### Database Functions

Only `service_role` can execute:

```text
save_affiliate_attribution
place_order_secure
request_affiliate_payout
submit_affiliate_application
review_affiliate_application
review_affiliate_payout
```

`place_order_secure`:

- Resolves the Firebase UID to `users.id`.
- Verifies the address belongs to the user.
- Rejects empty or unavailable carts.
- Loads current prices from `item_properties`.
- Validates affiliate/voucher/promotion codes.
- Prevents self-referral.
- Calculates discount and commission.
- Inserts order master and details in one transaction.
- Inserts the ledger row.
- Consumes attribution.
- Clears the database cart.

## Edge Function

Path:

```text
supabase/functions/affiliate-program/index.ts
```

Deploy without Supabase JWT verification because requests use Firebase ID
tokens and the function verifies them using Firebase Admin:

```bash
supabase functions deploy affiliate-program --no-verify-jwt
```

Required existing secrets:

```text
SUPABASE_URL
SUPABASE_SERVICE_ROLE_KEY
FIREBASE_PROJECT_ID
FIREBASE_CLIENT_EMAIL
FIREBASE_PRIVATE_KEY
```

Actions:

```text
validate_code
save_attribution
active_attribution
place_order
affiliate_profile
affiliate_dashboard
update_code
request_payout
affiliate_application_status
submit_affiliate_application
admin_affiliate_queue
review_affiliate_application
review_payout
set_affiliate_status
```

Only `validate_code` can be used without a logged-in user. Secure checkout,
profile mutation, dashboard data, and payouts require a verified Firebase user.

## Deployment Order

1. Apply the migration:

```bash
supabase db push --linked
```

2. Deploy the Edge Function:

```bash
supabase functions deploy affiliate-program --no-verify-jwt
```

3. Build and deploy the Flutter client.

Do not deploy the new client before both backend steps are ready.

## Local Database Verification

Fixtures:

```text
supabase/tests/affiliate_program_base_schema.sql
supabase/tests/affiliate_program_flow.sql
```

The flow test verifies:

- Existing affiliate receives a default code.
- Link attribution is saved.
- 10% customer discount is applied.
- 15% commission is calculated from the discounted total.
- Order values are snapshotted.
- Commission starts pending.
- Delivery makes it available.
- Payout request moves it to processing.
- Admin payment review with a transfer reference moves it to paid.
- Affiliate application approval provisions the requested code.
- New orders enqueue an admin-targeted notification.

## Troubleshooting

### Affiliate code shows `invalid_voucher`

1. Call the Edge Function validator with the exact code. The client must not
   query only the legacy `vouchers` table.
2. Confirm the affiliate has an active row in `affiliate_codes`.
3. Confirm the tester entered either the code or a URL containing `ref`; parse
   full share messages before validation.
4. Confirm the tester is running the affiliate-enabled client. Older native
   builds only know the legacy voucher lookup.
5. On Flutter web, compare the deployed `main.dart.js` with the current build
   and remove stale service-worker caches.

Do not copy affiliate codes into `vouchers` for backward compatibility. An old
client could grant a discount without securely creating the affiliate
commission ledger entry.

## Developer Actions

- Apply the migration in Supabase.
- Confirm every affiliate has a row in `affiliate_codes`.
- Manually set each affiliate's percentages.
- Review code requests for brand suitability.
- Decide the operational return window before approving payouts.
- Do not approve a payout for orders that may still be returned.
- Test with separate affiliate and customer accounts.
- Test link opening while logged out, then login and checkout.
- Test the same attribution on a second device.
- Test manual code override.
- Test self-referral rejection.
- Test voucher override/non-stacking.
- Test delivery, cancellation, return, payout rejection, and payout approval.

## Production Checklist

- Migration appears in `supabase migration list --linked`.
- `affiliate-program` is deployed with JWT verification disabled.
- Affiliate code validates at checkout.
- Link code appears automatically at checkout.
- Order total uses server prices.
- `order_master` contains snapshot fields.
- `affiliate_commissions` contains exactly one row per affiliate order.
- Affiliate dashboard totals match ledger statuses.
- Client cannot read/write ledger tables directly.
- Cancelled/returned unpaid orders do not remain payable.
