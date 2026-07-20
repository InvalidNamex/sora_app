# Sora — Apple App Store deployment guide

Last audited: **20 July 2026**

This guide is specific to the current Sora repository. It separates what is
already configured from decisions and external setup that still require the
Apple Developer account owner, Firebase owner, backend owner, and legal/business
owner.

## 1. Current release status

### Ready in the repository

- App name: `Sora`
- Bundle ID: `com.softforge.sora`
- Apple team ID: `WRHTJ9468B`
- App identifier used by universal links:
  `WRHTJ9468B.com.softforge.sora`
- Current Flutter version/build: `1.0.0+9`
- Minimum supported iOS version: iOS 15.0
- Supported devices: iPhone and iPad
- Supported app languages: English and Arabic
- Xcode on the audited Mac: Xcode 26.3 with the iOS 26.2 SDK
- Firebase iOS bundle ID matches `com.softforge.sora`
- The 1024 × 1024 App Store icon exists and has no alpha channel
- Push Notifications entitlement is present
- Production APNs environment is selected for Profile and Release builds
- Associated Domains entitlement is present for `www.sora-eg.store`
- Sign in with Apple entitlement and iOS-only Firebase sign-in flow are present
- The public Apple association file has the correct team and bundle ID
- Standard URL schemes for Google sign-in and `sora://` links are configured
- Photo-library and location purpose strings are present
- Standard/exempt encryption is declared with
  `ITSAppUsesNonExemptEncryption = false`
- An app privacy manifest is included in the Runner target
- Firebase/Google iOS pods currently include their own privacy manifests
- Only the public Supabase URL and anon key are bundled in `.env`; no service
  role key was found

### Verification completed during this audit

- `flutter analyze`: no issues
- `flutter test`: all 21 tests passed
- Unsigned Release archive: built successfully at
  `build/ios/archive/Runner.xcarchive`
- Flutter App Settings Validation: passed
- Archived version/build: `1.0.0 (9)`
- Archived bundle ID: `com.softforge.sora`
- Archived minimum iOS version: `15.0`
- Archived privacy manifest: present and valid
- Archived dSYMs: present, including `Runner.app.dSYM`

The archive is intentionally unsigned and is a compile/readiness artifact, not
an uploadable IPA. A final signed archive must be produced after the blockers
below are resolved.

### Repository changes made during this audit

- Added `ios/Runner/PrivacyInfo.xcprivacy`.
- Added the privacy manifest to the Runner target's resources.
- Declared English and Arabic bundle localizations.
- Declared that the app does not use non-exempt encryption.
- Removed unused background `fetch`; retained `remote-notification`.
- Reworded the photo-library permission to explain all authorized admin image
  use.
- Added `/bundle/*` to the local Apple universal-link association file.

### Compliance features implemented on July 20, 2026

1. **Sign in with Apple**

   Sora now shows Sign in with Apple next to Google on iOS only. The Apple
   button is hidden on Android and web. Apple-authenticated deletion obtains a
   fresh authorization code and revokes the Apple token before backend
   deletion.

   Remaining owner validation: enable Sign in with Apple for the App ID and
   provisioning profile, finish the Apple provider key/team configuration in
   Firebase, and test first/repeat/hidden-email login and deletion on a physical
   iPhone.

2. **In-app account deletion**

   The drawer now includes an authenticated, destructive confirmation form.
   The live Firebase-verified backend erases non-required data, anonymizes
   order-linked address placeholders and final-order delivery details, retains
   active delivery snapshots only through fulfilment, preserves order/financial
   ledgers, deletes the Firebase identity, and clears the local session.

   Remaining owner validation: have Egyptian legal/accounting counsel approve
   the retention categories and run deletion tests for phone, Google, and Apple
   accounts using disposable production/test users.

3. **Live privacy policy and in-app link**

   The drawer now links to the full policy and the web build includes the
   permanent static route:

   - `https://www.sora-eg.store/privacy_policy`

   Remaining owner validation: approve the policy text legally and enter this
   exact URL in App Store Connect.

## 2. Clarifications the owner must provide

Record the answers here before submission:

- [ ] Legal seller/developer name:
- [ ] Copyright owner text, for example `2026 Sora Egypt`:
- [ ] App Store support URL:
- [x] Privacy policy URL: `https://www.sora-eg.store/privacy_policy`
- [ ] Optional marketing URL:
- [ ] Support email confirmed as monitored: `support@sora-eg.store`
- [ ] Support phone confirmed: `+20 111 105 8359`
- [ ] Primary App Store language: English or Arabic:
- [ ] Primary category: recommended **Shopping**
- [ ] Secondary category: optional **Lifestyle**
- [ ] Distribution countries/regions:
- [ ] Will the app be distributed in the EU? If yes, complete DSA trader status.
- [ ] Legal answer on retained order records after account deletion:
- [x] Login decision: Sign in with Apple on iOS; hidden on Android/web
- [ ] Does Sora or any partner use app data to track users across other
      companies' apps/websites? Current code indicates **No**.
- [ ] Does affiliate attribution remain entirely first-party? Current code
      indicates **Yes**.
- [ ] Does the app use only TLS/standard OS encryption and no proprietary crypto?
      Current code indicates **Yes**.
- [ ] Is iPad support intentional? It is currently enabled and requires iPad
      screenshots and iPad QA.
- [ ] Non-admin App Review demo credentials:
- [ ] Admin demo credentials or review explanation:
- [ ] A phone OTP test number/code that works for App Review without requiring
      access to a real employee phone:

## 3. Apple Developer account setup

Use an Account Holder or Admin account at
[Certificates, Identifiers & Profiles](https://developer.apple.com/account/resources/identifiers/list).

### App identifier

Create or verify the explicit App ID:

- Description: `Sora`
- Bundle ID: `com.softforge.sora`
- Team ID: `WRHTJ9468B`

Enable these capabilities:

- Push Notifications
- Associated Domains
- Sign in with Apple, if retaining Google sign-in

After changing capabilities, let Xcode regenerate managed profiles or recreate
manual Development and App Store distribution profiles.

### Signing

Open `ios/Runner.xcworkspace`, not `Runner.xcodeproj`.

In Runner > Signing & Capabilities:

- Team: the team with ID `WRHTJ9468B`
- Bundle Identifier: `com.softforge.sora`
- Automatically manage signing: recommended
- Confirm Push Notifications
- Confirm Associated Domains contains:
  `applinks:www.sora-eg.store`
- Add Sign in with Apple if that login path is chosen

The raw Release build settings currently show `Apple Development` with
automatic signing. This is acceptable for creating an archive only if Xcode's
Organizer export step re-signs it for **App Store Connect** with a managed Apple
Distribution certificate/profile. Do not distribute a development-signed IPA.

## 4. Sign in with Apple decision

Apple's current login rule is in
[App Review Guideline 4.8](https://developer.apple.com/app-store/review/guidelines/#login-services).

If implementing Sign in with Apple:

1. Enable Sign in with Apple on the Apple App ID.
2. Add the capability to the Runner target.
3. Enable the Apple provider in Firebase Authentication.
4. Create/configure the Apple key, team ID, key ID, and private key in Firebase.
5. If the web app will also use Apple login, create a Services ID and configure
   the website domain/return URL.
6. Implement Firebase Apple authentication using a nonce.
7. Place the official Apple button at least as prominently as Google on iOS.
8. Handle users who hide their email.
9. Link Apple credentials to an existing Sora account only after explicit,
   authenticated user confirmation.
10. When deleting an Apple-authenticated account, revoke the Apple token as
    part of deletion.
11. Test first login, repeat login, cancellation, hidden email, credential
    revocation, and account deletion on a real device.

If removing Google on iOS:

1. Hide/remove the Google button only on iOS.
2. Verify phone OTP remains a reliable first-party login and registration path.
3. Explain phone verification to App Review and provide a test number/code.
4. Google can remain on Android/web if product requirements allow.

## 5. Account deletion implementation checklist

Apple's official requirement is documented at
[Offering account deletion in your app](https://developer.apple.com/support/offering-account-deletion-in-your-app/).

- [x] Add drawer > Delete Account.
- [x] Explain what is deleted immediately and what is legally retained.
- [x] Require a clear destructive confirmation.
- [x] Reauthenticate Apple users before token revocation.
- [x] Delete/deactivate the device's FCM token.
- [x] Delete addresses, cart, wishlist, active affiliate attribution, and other
      non-required personal records.
- [x] Delete or anonymize the Supabase `users` record according to retention
      rules.
- [x] Preserve only legally required order/accounting records and anonymize
      fields where permitted.
- [x] Handle pending orders, commissions, and payouts explicitly.
- [x] Delete the Firebase Auth identity through a privileged backend.
- [x] Revoke Sign in with Apple tokens for Apple-backed accounts.
- [x] Clear local storage and sign out.
- [x] Show completion or a precise error.
- [x] Update the privacy policy with retention/deletion behavior.
- [ ] Test deletion for phone, Google, and Apple accounts.

## 6. Firebase and push notifications

### Firebase iOS app

Verify in Firebase Console:

- iOS app bundle ID is exactly `com.softforge.sora`.
- The checked-in `ios/Runner/GoogleService-Info.plist` belongs to the production
  Firebase project.
- Google sign-in's reversed client ID matches the first URL scheme in
  `Info.plist`.
- Phone Authentication is enabled and production SMS regions/quotas/billing
  are configured.
- The App Store production build does not depend on Firebase test-only settings.

### APNs

In Firebase Console > Project Settings > Cloud Messaging:

1. Upload an APNs Authentication Key (`.p8`) for team `WRHTJ9468B`, including
   the correct Key ID and Team ID; or configure valid production certificates.
2. Verify the key has not expired/revoked.
3. Confirm the Runner App ID has Push Notifications enabled.
4. Test notifications on a real TestFlight device while the app is:

   - Foreground
   - Background
   - Force-quit
   - Opened by tapping the notification

5. Test notification deep links for item, bundle, order, and home destinations.
6. Confirm notification permission is requested in context and denial does not
   block shopping or checkout.

## 7. Universal links

The app entitlement uses:

```text
applinks:www.sora-eg.store
```

The public file currently responds with HTTP 200 and
`application/json; charset=utf-8`, and uses:

```text
WRHTJ9468B.com.softforge.sora
```

The repository association file now also includes `/bundle/*`. Redeploy the
website before the App Store build and verify:

```bash
curl -i https://www.sora-eg.store/.well-known/apple-app-site-association
```

Required characteristics:

- HTTPS with no authentication
- HTTP 200
- No redirect at the final association URL
- JSON content type
- Correct team ID and bundle ID
- Paths for `/item/*`, `/bundle/*`, `/orders/*`, `/ref/*`, and `/home`

Test links from Notes or Messages on a physical iPhone after installing through
TestFlight. Typing a URL directly in Safari is not a sufficient universal-link
test.

## 8. Privacy manifest and App Privacy answers

Apple requires App Privacy answers and a privacy policy URL. See:

- [Manage App Privacy](https://developer.apple.com/help/app-store-connect/manage-app-information/manage-app-privacy)
- [Privacy manifest files](https://developer.apple.com/documentation/bundleresources/privacy-manifest-files)
- [App Privacy details](https://developer.apple.com/app-store/app-privacy-details/)

The app privacy manifest declares that Sora does not track users and collects
the following data linked to the user's identity for app functionality:

- Name
- Email address
- Phone number
- Physical address
- Precise location
- Photos/videos selected by authorized admins
- Other user content, such as order notes or affiliate applications
- User ID
- Device ID/push token
- Purchase history
- Product interaction, including cart/wishlist behavior

Use this as the starting point for App Store Connect, then verify it with the
business and privacy-policy owner. App Store Connect disclosures must also
include third-party SDK practices.

Current source/configuration indicates:

- Firebase Analytics is disabled.
- Firebase Ads is disabled.
- No advertising SDK or IDFA access was found.
- No App Tracking Transparency prompt is needed if the business does not track
  users across other companies' apps/websites.
- Payment information is not collected because checkout is cash on delivery.
- Location is optional and requested only when the user asks to center the
  delivery map.
- Photos are selected only by authorized admin features.

If any marketing/affiliate partner receives identifiable data, or data is
combined across companies, revisit both the tracking answer and ATT requirement
before submission.

### Privacy policy minimum content

Have legal counsel approve the final policy. It should clearly cover:

- Legal entity and contact information
- Data categories listed above
- How each category is collected and used
- Firebase, Google Sign-In, Firebase Messaging, Supabase, and hosting providers
- Whether data is shared with delivery, support, infrastructure, or affiliate
  partners
- Confirmation that there is no cross-company tracking, if accurate
- Location and notification permission behavior
- Data security measures
- Retention periods, especially orders and affiliate/payment records
- Account deletion steps and exceptions required by law
- User rights and how to exercise them
- Children's privacy/age eligibility
- International data transfers
- Policy effective date and change process

Add the same privacy-policy URL inside the app.

## 9. Permissions and review explanation

The reviewer may ask why permissions exist. Use these accurate explanations:

- **Location:** optional; used only when the customer taps “Use current
  location” to center the delivery map and save a delivery pin.
- **Photos:** available only to authorized administrators selecting product,
  category, notification, or bundle imagery.
- **Notifications:** optional; used for order updates and Sora notifications.

The app must remain usable for browsing and normal non-location address entry
when location or notifications are denied.

## 10. Export compliance

The app uses HTTPS/TLS and platform/SDK cryptography, and no custom or
proprietary cryptographic implementation was found. The repository now sets:

```xml
<key>ITSAppUsesNonExemptEncryption</key>
<false/>
```

The legal/account owner must confirm that this remains accurate. Apple notes
that the developer is responsible for the export determination. See
[Overview of export compliance](https://developer.apple.com/help/app-store-connect/manage-app-information/overview-of-export-compliance/).

## 11. App Store Connect record

Create the app at [App Store Connect](https://appstoreconnect.apple.com/):

- Platforms: iOS
- Name: `Sora` (subject to availability)
- Primary language: owner decision; English is operationally simplest
- Bundle ID: `com.softforge.sora`
- SKU: for example `sora-ios-001` (cannot be changed later)
- User Access: Full Access unless the organization needs role restrictions

Recommended listing choices:

- Price: Free
- Primary category: Shopping
- Secondary category: Lifestyle, optional
- Physical-goods checkout: cash on delivery; do not add Apple In-App Purchase
  for perfumes. Apple Guideline 3.1.3(e) requires physical goods to use payment
  methods other than IAP.
- Complete the updated 2026 age-rating questionnaire. Do not assume the final
  rating; let App Store Connect calculate it from accurate answers.
- Complete Content Rights.
- Complete DSA trader status before EU distribution.
- Review availability for Egypt and every selected storefront.

## 12. Suggested English metadata

Confirm all claims with the business owner.

**Name**

```text
Sora
```

**Subtitle** (30 characters maximum)

```text
Perfumes & curated bundles
```

**Promotional text**

```text
Discover fragrances, exclusive bundle deals, and convenient cash-on-delivery ordering from Sora.
```

**Description**

```text
Discover fragrances for every style with Sora.

Browse curated perfume collections, explore sizes and product details, save favorites, and find exclusive bundle deals. Build your cart as a guest, sign in securely, save delivery addresses, and place cash-on-delivery orders.

Features:
• Arabic and English support
• Perfume categories and detailed product options
• Exclusive fixed-price bundle deals
• Favorites and order history
• Saved delivery addresses with optional map pinning
• Promo and affiliate codes on eligible non-bundle orders
• Order updates and notifications

Need help? Contact the Sora support team from within the app.
```

**Keywords** (100 characters maximum; do not repeat the app name)

```text
perfume,fragrance,shopping,bundles,beauty,attar,عطور,عطر,تسوق
```

**Review the exact character counts in App Store Connect before saving.**

## 13. Suggested Arabic metadata

Have a native Arabic marketing reviewer approve it.

**Name**

```text
سورا
```

**Subtitle**

```text
عطور وباقات مختارة
```

**Promotional text**

```text
اكتشف العطور وعروض الباقات الحصرية واطلب بسهولة مع الدفع عند الاستلام من سورا.
```

**Description**

```text
اكتشف عطرك المناسب مع سورا.

تصفح مجموعات العطور، واختر الأحجام المناسبة، واحفظ منتجاتك المفضلة، واستفد من عروض الباقات الحصرية. يمكنك تجهيز سلتك كزائر، ثم تسجيل الدخول بأمان وحفظ عناوين التوصيل وإتمام طلبك مع الدفع عند الاستلام.

المميزات:
• دعم العربية والإنجليزية
• تصنيفات عطور وخيارات تفصيلية للمنتجات
• عروض باقات حصرية بسعر ثابت
• المفضلة وسجل الطلبات
• حفظ عناوين التوصيل مع تحديد اختياري على الخريطة
• أكواد خصم وتسويق للطلبات المؤهلة غير المحتوية على باقات
• إشعارات وتحديثات الطلبات

للمساعدة، تواصل مع فريق دعم سورا من داخل التطبيق.
```

**Keywords**

```text
عطور,عطر,تسوق,باقات,جمال,برفان,perfume,fragrance,shopping
```

## 14. Screenshots and product-page assets

Apple allows one to ten screenshots per supported device class. Because Sora
currently supports both iPhone and iPad, prepare both:

- iPhone 6.9-inch portrait: use an accepted size such as
  `1320 × 2868`, `1290 × 2796`, or `1260 × 2736`.
- iPad 13-inch portrait: `2064 × 2752` or `2048 × 2732`.
- Screenshots must not contain an alpha channel.

Always recheck
[Apple's current screenshot specifications](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications/)
before export.

Recommended screenshot sequence in both English and Arabic:

1. Home, categories, and featured products
2. Product detail with size/price options
3. Bundle Deal banner and bundle page
4. Cart with bundle savings
5. Checkout and cash-on-delivery summary
6. Favorites/order history or delivery map

Do not show real customer names, phone numbers, addresses, order IDs, push
tokens, or admin secrets. Use dedicated demo data.

## 15. App Review access and notes

Apple expects a fully functional backend and demo access for apps with login.
Phone OTP tied to a real employee is unreliable for review.

Recommended setup:

- Create a stable non-admin reviewer user.
- Configure a Firebase test phone number and fixed code for that user, or
  provide another review-safe login path.
- Create a separate admin reviewer user only if Apple needs to inspect admin
  image/notification features.
- Keep all demo catalog data, bundles, addresses, and order flow active during
  review.
- Do not require the reviewer to contact support for credentials.

Suggested review notes:

```text
Sora is an e-commerce app for physical perfume products. All purchases are for
physical goods delivered outside the app and use cash on delivery; the app does
not sell digital content and does not use Apple In-App Purchase.

Location is optional and requested only when the user chooses to center the
delivery-address map. Photo-library access is limited to authorized admin
accounts uploading catalog, notification, and bundle imagery. Push
notifications are optional and used for order updates.

Bundle Deal prices are fixed. Promo and affiliate codes are intentionally
disabled whenever a cart contains a bundle.

Reviewer login:
Phone: [TEST PHONE]
OTP: [FIXED TEST CODE]

Steps:
1. Browse products or open Bundle Deal on Home.
2. Add a product or bundle to the cart.
3. Proceed to checkout and sign in with the reviewer account.
4. Select the demo address and place a cash-on-delivery order.

Account deletion is available in the side drawer under Delete Account.
Privacy policy: https://www.sora-eg.store/privacy_policy
```

## 16. Pre-release test matrix

Test on at least one physical iPhone and one supported iPad:

- [ ] Fresh install and splash screen
- [ ] Upgrade from the previous TestFlight build
- [ ] English LTR and Arabic RTL
- [ ] Light and dark modes
- [ ] Guest browsing, regular cart, and bundle cart
- [ ] Guest cart synchronization after login
- [ ] Phone OTP login
- [ ] Google login plus Sign in with Apple, or the approved login alternative
- [ ] Sign out and sign back in
- [ ] Account deletion for every login provider
- [ ] Product option, stock, and price handling
- [ ] Bundle quantity multiplication and fixed internal quantities
- [ ] Promo allowed on regular orders
- [ ] Promo blocked on bundle and mixed carts
- [ ] Address create/edit/delete/default
- [ ] Location permission allowed, approximate, denied, and denied forever
- [ ] Checkout phone/address validation
- [ ] Cash-on-delivery order placement
- [ ] Order history and localized product names
- [ ] Push permission allowed and denied
- [ ] Foreground/background/terminated push delivery
- [ ] Notification deep links
- [ ] Universal links for item, bundle, order, referral, and home
- [ ] Offline/slow network and backend error states
- [ ] iPad portrait and landscape layouts
- [ ] No clipped text at larger Dynamic Type sizes
- [ ] VoiceOver labels and minimum tap targets for primary checkout controls
- [ ] No real personal data in demo accounts/screenshots
- [ ] Production Supabase/Firebase functions and buckets are available

## 17. Version and build numbers

Current source value:

```yaml
version: 1.0.0+9
```

- `1.0.0` is the marketing/version number.
- `9` is the build number.
- App Store Connect matches builds by bundle ID and version.
- Every uploaded build for the same version needs a unique, increasing build
  number.

If build 9 has never been uploaded, it may be used. If its upload history is
unknown, increment to build 10 before upload:

```bash
flutter build ipa --release --build-name=1.0.0 --build-number=10
```

Do not change the bundle ID after the first App Store Connect build.

## 18. Build and archive

### Automated checks

From the repository root:

```bash
flutter pub get
flutter analyze
flutter test
plutil -lint ios/Runner/Info.plist
plutil -lint ios/Runner/Runner.entitlements
plutil -lint ios/Runner/PrivacyInfo.xcprivacy
```

Install/update pods when dependencies change:

```bash
cd ios
pod install --repo-update
cd ..
```

### Recommended signed archive

1. Open `ios/Runner.xcworkspace`.
2. Select the Runner scheme and **Any iOS Device (arm64)**.
3. Confirm Release signing/capabilities.
4. Product > Archive.
5. In Organizer, run **Validate App**.
6. Choose **Distribute App > App Store Connect > Upload**.
7. Let Xcode manage distribution signing unless the organization deliberately
   uses manual profiles.
8. Review every validation warning before upload.

Alternatively:

```bash
flutter build ipa --release --build-name=1.0.0 --build-number=10
```

Use a signed build with the correct team/profile. An archive produced with
`--no-codesign` is only a compile check and cannot be uploaded.

## 19. Inspect the final archive

Before uploading, verify:

- Bundle ID is `com.softforge.sora`
- Version/build are correct
- Minimum OS is iOS 15.0
- App icon appears correctly
- `PrivacyInfo.xcprivacy` is at the root of `Runner.app`
- `GoogleService-Info.plist` is present
- Release entitlements contain production APNs and associated domains
- No service-role keys, private keys, `.p8`, certificates, or passwords exist
  in the app bundle
- dSYM/symbols are included

Example commands, adjusting the archive path:

```bash
APP="build/ios/archive/Runner.xcarchive/Products/Applications/Runner.app"
plutil -p "$APP/Info.plist"
test -f "$APP/PrivacyInfo.xcprivacy"
codesign -d --entitlements :- "$APP"
```

In Xcode Organizer, generate the privacy report:

```text
Archive > Privacy & Security > Generate Privacy Report
```

Compare the report with the manifest, App Store Connect privacy answers, and
published privacy policy.

## 20. TestFlight

Apple's current flow is documented in
[TestFlight Overview](https://developer.apple.com/help/app-store-connect/test-a-beta-version/testflight-overview/).

1. Wait for uploaded build processing to complete.
2. Resolve Missing Compliance if it appears.
3. Add internal testers first.
4. Test on production APNs and production backend configuration.
5. Complete Test Information:

   - Beta App Description
   - Feedback Email
   - Contact Information
   - What to Test
   - Review credentials

6. Add an external group if needed. The first external build may require Beta
   App Review.
7. Complete at least one full physical-device order and account-deletion test
   from the TestFlight build.

## 21. Final App Store Connect checklist

- [ ] Agreements are accepted and membership is active.
- [ ] App record uses `com.softforge.sora`.
- [ ] Name, subtitle, description, keywords, and categories are complete.
- [ ] English and Arabic metadata are proofread.
- [ ] Privacy policy URL is live and matches the in-app link.
- [ ] App Privacy answers match the final privacy report.
- [ ] Age-rating questions are complete.
- [ ] Content Rights are complete.
- [ ] DSA trader status is complete if distributing in the EU.
- [ ] Export compliance is accurate.
- [ ] Availability and pricing are set.
- [ ] iPhone 6.9-inch screenshots are uploaded.
- [ ] iPad 13-inch screenshots are uploaded, or iPad support was deliberately
      removed and retested before build.
- [ ] Support URL is live.
- [ ] App Review contact and demo credentials work.
- [ ] Review notes explain physical-goods/COD checkout and permissions.
- [ ] Correct processed build is selected.
- [ ] TestFlight regression is complete.
- [ ] Release method is selected: manual, automatic, or scheduled.
- [ ] Add for Review, then Submit for Review.

Apple's current submission steps:
[Submit an app](https://developer.apple.com/help/app-store-connect/manage-submissions-to-app-review/submit-an-app).

## 22. Current Apple toolchain requirement

As of this audit date, Apple states that uploads since 28 April 2026 must use
Xcode 26 or later with the iOS 26 SDK or later. The audited Mac satisfies this
with Xcode 26.3 and iOS SDK 26.2.

Always recheck
[Apple Upcoming Requirements](https://developer.apple.com/news/upcoming-requirements/)
immediately before the final archive because requirements can change.

## 23. Go/no-go gate

The app is **not ready to submit for App Review** until:

- Sign in with Apple is configured in the Apple Developer portal/Firebase and
  tested on a physical iPhone.
- In-app account deletion is tested for phone, Google, and Apple users.
- The published privacy policy is reviewed and approved by the owner/legal
  adviser.
- Review-safe credentials are tested.
- APNs production delivery is confirmed from TestFlight.
- The updated website association file is deployed.
- iPhone and iPad screenshots are ready.

Once those items are complete, produce a new signed build with a fresh build
number, validate it in Organizer, run TestFlight regression, and submit.
