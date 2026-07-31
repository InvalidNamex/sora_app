# Sora Store — Google Play deployment guide

Last verified: July 21, 2026

This guide covers the first Google Play release of the Android app. It records
the values already configured in the project and the manual work that must be
completed in Play Console.

## 1. Current release status

The repository is configured with:

| Field | Value |
| --- | --- |
| Play listing/app label | Sora Store |
| Android package name | `com.softforge.sora` |
| Version name | `1.0.0` |
| Version code | `10` |
| Minimum Android version | Android 7.0 / API 24 |
| Target Android version | Android 16 / API 36 |
| Release format | Android App Bundle (`.aab`) |
| Privacy policy | `https://www.sora-eg.store/privacy_policy` |
| Account deletion URL | `https://www.sora-eg.store/delete-account` |
| Support email | `support@sora-eg.store` |
| Support phone | `+20 111 105 8359` |

The signed release bundle is generated at:

```text
build/app/outputs/bundle/release/app-release.aab
```

The July 21 build was 54.3 MB and had SHA-256:

```text
e50a5491a3af0a6d9dbbb00f6d6b536f94984c50dc8ae4827044233ad45f4c7f
```

Rebuilding changes the checksum. Always upload the newest bundle after making
code, dependency, configuration, or asset changes.

### Verified locally

- The App Bundle is signed with the Sora upload certificate.
- The manifest contains package `com.softforge.sora`.
- The manifest contains version `1.0.0 (10)`.
- The manifest targets API 36.
- The manifest app label is `Sora Store`.
- The release uses R8 and contains its mapping metadata.
- APK signature verification passes.
- 16 KB ZIP alignment passes.
- Every packaged ARM64 and x86-64 native library has ELF load-segment
  alignment of at least 16 KB.
- The privacy-policy and account-deletion URLs return HTTP 200.
- The Android App Links file is served as JSON.

Google requires new apps and updates to target API 36 beginning August 31,
2026. This build already targets API 36. Google also requires apps targeting
Android 15 or later to support 16 KB pages; this build passes both the ZIP and
native-library alignment checks.

Official references:

- <https://developer.android.com/google/play/requirements/target-sdk>
- <https://developer.android.com/guide/practices/page-sizes>

## 2. Protect the upload key

The following local files are intentionally ignored by Git:

```text
android/key.properties
android/app/sora-release.jks
```

They must never be committed, sent in chat, attached to a ticket, or placed in
public cloud storage. Make encrypted backups of both files and securely record
their passwords. Losing the upload key is recoverable through Play Console,
but recovery delays releases; losing passwords or leaking the key creates an
avoidable security incident.

The current upload certificate fingerprints are:

```text
SHA-1:   10:57:02:D9:3E:61:65:CC:37:E1:78:9D:22:E6:17:27:7C:AB:33:B1
SHA-256: 1A:12:0F:AF:0B:23:AB:DD:75:3A:02:CA:03:84:D0:0B:11:DE:BD:D1:21:C6:F8:09:17:8E:6E:90:81:44:4F:D0
```

The Gradle configuration now refuses a release build when
`android/key.properties` is absent. It never silently publishes with the
shared Android debug key.

Use Play App Signing when Play Console offers it. For a new app, the normal
recommended option is to let Google generate and protect the app-signing key;
the local Sora key remains the **upload key** used to authenticate future
uploads.

Official reference:

- <https://support.google.com/googleplay/android-developer/answer/9842756>

## 3. Build and verify a release

From the repository root:

```bash
flutter clean
flutter pub get
flutter analyze
flutter test
flutter build appbundle --release
```

Do not run `flutter clean` after creating the final bundle until the bundle has
been uploaded or copied to a safe release-artifact location.

Every uploaded bundle must have a unique, increasing version code. Before the
next release, update `pubspec.yaml`, for example:

```yaml
version: 1.0.1+11
```

Do not increment version code `10` before the first upload unless Play Console
says code 10 has already been used. An uploaded version code can never be
reused, even if its release was discarded.

### Sentry symbols

Sentry is initialized in the release app. After producing the final bundle,
upload Dart symbols from the repository root:

```bash
dart run sentry_dart_plugin
```

Keep `sentry.properties` private. Do not paste its token into Play Console,
source control, screenshots, or support messages. Sentry symbol upload and
Google Play upload are independent; a Sentry failure does not invalidate the
App Bundle, but crashes may have less useful stack traces until symbols are
uploaded.

## 4. Create the Play Console app

1. Open <https://play.google.com/console/>.
2. Complete developer identity, contact, payment-profile, and verification
   tasks shown on the account dashboard.
3. Choose **Create app**.
4. Enter app name **Sora Store**.
5. Choose the primary default language. Use English if the initial listing
   below is used; add an Arabic localization separately.
6. Select **App**, not Game.
7. Select **Free**. A free app cannot later be changed to paid, but Sora can
   still sell physical goods using cash on delivery.
8. Accept the declarations and create the app.

The package name is fixed by the first uploaded bundle. Confirm Play Console
shows `com.softforge.sora` before continuing. Package names cannot be renamed
after publication.

## 5. Main store listing

Recommended settings:

| Field | Recommended value |
| --- | --- |
| App name | Sora Store |
| App category | Shopping |
| Tags | Choose only accurate shopping/beauty tags offered by Play Console |
| Support email | `support@sora-eg.store` |
| Website | `https://www.sora-eg.store` |
| Privacy policy | `https://www.sora-eg.store/privacy_policy` |

### Suggested English short description

```text
Shop perfumes, cosmetics, bundles, and exclusive Sora deals in Egypt
```

This is within Play's 80-character limit.

### Suggested English full description

```text
Discover perfumes, cosmetics, and curated bundle deals from Sora Store.

Browse products and collections, review item details, save favorites, and add individual products or fixed-quantity bundle deals to your cart. Bundle pricing clearly shows the regular total and the deal price before checkout.

Create an account to save delivery addresses, follow your order history, receive order updates, and manage your account. Choose a delivery location on the map when it is useful, or enter an address manually. Location access and notifications are optional and requested only when needed.

Orders are currently paid by cash on delivery. Sora Store does not collect payment-card details.

Available features include:
- Perfumes and cosmetics catalog
- Curated bundle deals
- Wishlist and cart
- Promo codes for eligible non-bundle purchases
- Saved delivery addresses
- Cash on delivery
- Order history and status notifications
- In-app privacy and account-deletion controls

Sora Store currently serves customers in Egypt. Product selection, prices, availability, and delivery coverage may change.
```

Review this marketing copy against the live app immediately before submission.
Remove any feature that is not available to ordinary customers in the submitted
build.

### Graphics to upload

- **App icon:** 512 × 512, 32-bit PNG, at most 1 MB. The current source asset
  `assets/images/logoWithBG.png` is 512 × 512; export a Play-ready PNG and
  confirm its appearance in Play Console.
- **Feature graphic:** 1024 × 500, JPEG or 24-bit PNG without alpha. This still
  needs to be designed/exported.
- **Phone screenshots:** upload at least two. Four portrait screenshots at
  1080 × 1920 or higher are recommended for merchandising eligibility.
- Suggested screenshot sequence: home/catalog, bundle deal, product detail,
  cart/checkout, and order tracking. Use realistic non-sensitive sample data.
- Remove personal phone numbers, emails, addresses, notification content,
  debug banners, emulator controls, and admin-only data from screenshots.

Official asset requirements:

- <https://support.google.com/googleplay/android-developer/answer/9866151>

## 6. App content declarations

Complete every card under **Policy and programs → App content**. Console wording
can change, so answer according to the submitted build rather than blindly
copying this guide.

### Privacy policy

Use:

```text
https://www.sora-eg.store/privacy_policy
```

The same policy is available in the app drawer.

### Ads

Answer **No** if the submitted app still contains no advertising SDK and does
not display third-party paid advertisements. Product banners and Sora's own
promotions are store content, not third-party ad-network ads.

### App access

The catalog is available to guests, but checkout, saved addresses, order
history, affiliate screens, and account deletion require authentication.
Choose **All or some functionality is restricted** and provide Google with a
dedicated review account and exact steps.

Suggested review instructions:

```text
The catalog and product pages are available without signing in. To review
account-only features, sign in using the review credentials below. Open the
side drawer for Orders, My Addresses, Privacy Policy, and Delete Account.
Checkout uses cash on delivery and no real payment-card details are required.
Please do not place a real order; stop before the final Place Order action, or
use the test delivery details supplied below if an order is required for
review.
```

Create and test the review account before submission. Do not give reviewers an
administrator account. Keep the account active throughout review.

### Target audience

The privacy policy says the service is not directed to children under 13. The
store sells perfume and cosmetics rather than child-directed content. Select
only the truthful non-child age groups for the business's intended customers;
do not select an under-13 group unless the app is redesigned and reviewed for
the Families policy. A conservative commerce listing normally uses adult age
groups, subject to the business owner's actual audience decision.

### Content rating

Complete the IARC questionnaire accurately as a shopping app. Do not guess the
final rating. Answer based on every type of product, promotion, user-generated
content, communication feature, and external link present in the submitted
app.

### Other declarations

For the current customer app, the expected answers are:

- News or magazine app: **No**.
- Government app: **No**.
- Health app: **No**, assuming no health or medical claims are added.
- Financial features: **None**. Cash on delivery for physical goods is not a
  wallet, lending, banking, trading, or money-transfer product.
- Advertising ID: the app does not intentionally use an ad SDK or request the
  `AD_ID` permission. Re-check Play's detected permissions after upload.
- COVID-19/contact tracing: **No**.

If Play Console detects a declaration not listed here, investigate why it was
triggered before answering.

## 7. Data safety form

Google requires declarations to include data handled by the app and every
third-party SDK. The form must match the live privacy policy. The project uses
Firebase, Supabase, Sentry, mapping tiles/services, Vercel-hosted web pages, and
delivery/support workflows.

Current app behavior indicates the following data types should be reviewed and
normally declared as **collected** where Play asks for them:

| Play data category | Sora examples | Required or optional | Main purposes |
| --- | --- | --- | --- |
| Name | Customer/account name | Account/order dependent | Account management, app functionality |
| Email address | Firebase or social-login email | Depends on sign-in method | Authentication, account management |
| Phone number | Phone sign-in and delivery contact | Required for relevant sign-in/order flow | Authentication, order fulfilment |
| User IDs | Firebase UID and Sora user record | Required for signed-in use | Authentication, account management |
| Address | Saved and order delivery address | Required to deliver an order | App functionality, order fulfilment |
| Precise location | Map pin/device location when chosen | Optional | Create a delivery address |
| Approximate location | OS-derived location | Optional | Create a delivery address |
| Purchase history | Products, bundles, discounts, order status | Required for an order | Order fulfilment, account history |
| App interactions | Cart, wishlist, affiliate/referral activity where retained | Feature dependent | App functionality |
| Crash logs | Sentry crash/error reports | Automatic for app reliability | App functionality, diagnostics |
| Diagnostics | Stack traces, device/app technical details, performance/hang data | Automatic for app reliability | App functionality, diagnostics |
| Device or other IDs | FCM installation/device notification token and SDK identifiers | Notification/SDK dependent | Notifications, security, app functionality |
| Photos | Admin-selected catalog/banner images | Admin-only and optional | App functionality |

Important qualifications:

- Current customer orders use cash on delivery. Do **not** declare payment-card
  data unless a future release begins collecting it.
- Location is optional and requested only when the user chooses current
  location. Users can enter an address without location permission.
- Notification permission is optional, but a device token may be processed by
  Firebase when notifications are enabled/configured.
- Admin image upload exists in the same binary. The Data safety form covers the
  whole distributed binary, not only normal customer roles.
- Sentry's diagnostic collection must be included even though the data is used
  only for reliability.
- Confirm whether Google defines each provider relationship as collection or
  sharing for the final SDK configuration. Do not claim “no sharing” without
  checking the current Data safety guidance for every processor.

Security/deletion answers supported by the current implementation:

- Data is encrypted in transit: **Yes** for the app's HTTPS/TLS services.
- Users can request deletion: **Yes**.
- In-app path: side drawer → **Delete Account**.
- Web deletion URL: `https://www.sora-eg.store/delete-account`.
- Necessary order/accounting records may be retained only for disclosed legal,
  accounting, fraud-prevention, dispute, or order-fulfilment reasons. Other
  account data is erased or anonymized by the deletion flow.

Official references:

- <https://support.google.com/googleplay/android-developer/answer/10787469>
- <https://support.google.com/googleplay/android-developer/answer/13327111>
- <https://support.google.com/googleplay/android-developer/answer/10144311>

## 8. Upload first to a test track

Use **Test and release → Testing → Internal testing** first:

1. Create the internal test release.
2. Accept/configure Play App Signing using Google's recommended key option.
3. Upload `build/app/outputs/bundle/release/app-release.aab`.
4. Confirm Play reports package `com.softforge.sora`, version `1.0.0`, version
   code `10`, target API 36, and no blocking errors.
5. Add release notes, for example:

   ```text
   Initial Sora Store release with product browsing, bundle deals, cart,
   wishlist, cash-on-delivery checkout, saved addresses, order updates,
   privacy controls, and account deletion.
   ```

6. Add internal testers and roll out the internal release.
7. Install through the Google Play opt-in link. Do not rely only on a locally
   installed APK, because the Play-delivered app uses Google's signing key and
   delivery splits.

Official release guide:

- <https://support.google.com/googleplay/android-developer/answer/9859348>

## 9. Required post-upload signing updates

Google Play signs delivered APKs with a new **app-signing certificate**, which
is different from the local upload certificate.

After the first bundle is processed:

1. Open **Test and release → App integrity** (the exact section label may
   appear under Play App Signing/App signing).
2. Find **App signing key certificate**, not Upload key certificate.
3. Copy its SHA-1 and SHA-256 fingerprints.
4. In Firebase Console, open project **sora-eg** → Project settings → Android
   app `com.softforge.sora`.
5. Add the Play **app-signing** SHA-1 and SHA-256 fingerprints.
6. Download the refreshed `google-services.json` if Firebase instructs you to
   and replace `android/app/google-services.json` before the next build.
7. Add the Play app-signing SHA-256 fingerprint to
   `web/.well-known/assetlinks.json` without removing the upload/debug
   fingerprints.
8. Rebuild the web app and deploy the updated `.well-known` file to Vercel.
9. Verify:

   ```bash
   curl https://www.sora-eg.store/.well-known/assetlinks.json
   ```

10. Test Google Sign-In and an HTTPS app link using the Play-installed build.

This step is essential. Without the Play signing SHA values, Google Sign-In or
verified HTTPS App Links can fail only in the Play-distributed build while
working in local debug/release builds.

## 10. Test checklist on the Play-installed build

Run these tests on at least one current Android device and, where practical,
one Android 7–9 device or emulator:

- Fresh install launches without a crash or blank screen.
- App name and launcher icon are correct.
- Guest can browse home, catalog, product details, and bundle deals.
- Bundle banner opens the correct bundle.
- Bundle quantity multiplies fixed item quantities and price correctly.
- Bundle checkout does not allow line-item quantity editing.
- Promo codes are blocked when a bundle is present and work when eligible.
- Add to cart can proceed to checkout without the removed snackbar.
- Phone and Google sign-in work. Apple sign-in remains hidden on Android.
- Notification permission is requested in context and denial is handled.
- Location permission is requested only after **Use current location**.
- Manual address entry works when location is denied.
- Cash-on-delivery order flow works with a controlled test account/order.
- Order status/history works.
- Privacy Policy opens from the drawer.
- Delete Account opens and completes correctly with a disposable account.
- HTTPS deep links from `www.sora-eg.store` open the app.
- Arabic and English layouts are readable.
- Back navigation, rotation, keyboard, offline/error states, and app resume work.
- Sentry receives a controlled non-production test event if the business has a
  safe test procedure. Do not deliberately crash a production user's session.

Review Play Console's **Pre-launch report**, **App bundle explorer**, **Policy
status**, **Android vitals**, and device-compatibility warnings before applying
for production.

## 11. Closed testing requirement for newer personal accounts

If the Play developer account is a personal account created after November 13,
2023, Google currently requires a closed test with at least **12 opted-in
testers for 14 continuous days** before production access can be requested.
Start this immediately after internal verification. Removing/replacing testers
can interrupt the continuous qualification period.

Official reference:

- <https://support.google.com/googleplay/android-developer/answer/14151465>

Organization accounts and older personal accounts may not see this gate; follow
the dashboard requirements shown for the actual account.

## 12. Production release

When all dashboard tasks, declarations, listing assets, reviews, and required
testing are complete:

1. Configure **Countries/regions** and confirm Egypt is included.
2. Confirm the app is Free and that all sales are for physical goods outside
   Google Play Billing.
3. Apply for production access if the account has the closed-test gate.
4. Create the production release and promote the tested bundle rather than
   rebuilding unnecessarily.
5. Review Play's warnings and errors. Resolve all blocking policy and technical
   issues.
6. Confirm managed publishing/release timing. The first production release
   cannot use a percentage staged rollout in the same way as later updates.
7. Submit the changes for review.
8. Keep the review account, backend, privacy policy, deletion URL, Firebase,
   Supabase, images, and support contact operational throughout review.

After approval, verify the public listing and install from Google Play. Monitor
Play Android vitals, Firebase authentication, Supabase logs, notification
delivery, Sentry, reviews, order creation, and support messages.

## 13. Items still requiring owner action

- Create/verify the Google Play developer account and payment profile.
- Make encrypted offline backups of the upload keystore and passwords.
- Create the Play Console app record.
- Approve the suggested listing copy.
- Create the 1024 × 500 feature graphic.
- Capture at least two, preferably four or more, clean phone screenshots.
- Choose the real target audience and complete the IARC questionnaire.
- Create a non-admin reviewer account and review instructions.
- Complete the Data safety form after confirming all business/provider data
  handling.
- Upload the AAB to internal testing and configure Play App Signing.
- Add Play's app-signing SHA fingerprints to Firebase and `assetlinks.json`.
- Run the Play-installed build test checklist.
- Complete the closed test if the developer account is subject to it.
- Submit the production release.

Do not publish until these owner/console items are complete.
