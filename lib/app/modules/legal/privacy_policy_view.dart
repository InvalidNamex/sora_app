import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/constants/app_constants.dart';

class PrivacyPolicyView extends StatelessWidget {
  const PrivacyPolicyView({super.key});

  static const _sections = <({String title, String body})>[
    (
      title: '1. Who we are',
      body:
          'Sora is an online fashion store operated in Egypt. This policy '
          'explains how Sora collects, uses, stores, and shares personal '
          'information when you use the Sora mobile app or website.',
    ),
    (
      title: '2. Information we collect',
      body:
          'We may collect your name, email address, phone number, Firebase '
          'account identifier, saved delivery addresses, order details, cart '
          'and wishlist activity, customer-support communications, affiliate '
          'program information, and device notification tokens. If you choose '
          'a location on the map, we use the selected or device location to '
          'help create a delivery address. We do not collect payment-card '
          'details because current orders are paid by cash on delivery.',
    ),
    (
      title: '3. Sign-in information',
      body:
          'Authentication is provided through Firebase Authentication. '
          'Depending on your device, you may sign in with a phone number, '
          'Google, or Sign in with Apple. Those providers process information '
          'under their own privacy policies. When Apple provides a private '
          'relay email address, Sora stores and uses that relay address in the '
          'same way as any other account email.',
    ),
    (
      title: '4. How we use information',
      body:
          'We use information to create and secure your account; keep your '
          'cart and wishlist; fulfil, deliver, and support orders; send '
          'service and optional promotional notifications; operate promotions '
          'and the affiliate program; prevent fraud and misuse; improve app '
          'reliability; and meet legal, accounting, and regulatory duties.',
    ),
    (
      title: '5. Device permissions',
      body:
          'Location access is optional and is used only when you ask the app '
          'to help select a delivery location. Notification permission is '
          'optional and allows order updates and Sora messages. Photo-library '
          'access is used only by authorized administrators who choose images '
          'to upload for store content. You can change permissions in your '
          'device settings.',
    ),
    (
      title: '6. Service providers and sharing',
      body:
          'We share information only as needed with service providers that '
          'operate the app and store, including Firebase (authentication and '
          'notifications), Supabase (database, storage, and server functions), '
          'Vercel (website hosting), mapping services used to display maps, '
          'and delivery or support providers needed to complete an order. We '
          'may also disclose information when required by law or to protect '
          'users, Sora, or others. We do not sell personal information.',
    ),
    (
      title: '7. Retention',
      body:
          'We keep account information while your account is active and only '
          'as long as needed for the purposes described here. When an account '
          'is deleted, cart, wishlist, saved-address content, notification '
          'tokens, and other non-required account data are erased or '
          'anonymized. Order and financial records may be retained where '
          'needed to fulfil an active order or meet accounting, tax, fraud '
          'prevention, dispute, and legal obligations. Personal delivery '
          'details retained for an active order are anonymized when the order '
          'reaches a final status unless longer retention is legally required.',
    ),
    (
      title: '8. Account deletion and your choices',
      body:
          'Signed-in users can open the side drawer, choose Delete Account, '
          'and confirm the request inside the app. Deletion is permanent: your '
          'sign-in credential is removed and your account cannot be recovered. '
          'You may also contact us to ask about your information, correct it, '
          'or exercise rights available under applicable law.',
    ),
    (
      title: '9. Security and international processing',
      body:
          'We use reasonable technical and organizational safeguards, but no '
          'internet service can guarantee absolute security. Our technology '
          'providers may process information outside Egypt, subject to their '
          'contractual safeguards and applicable law.',
    ),
    (
      title: '10. Children',
      body:
          'Sora is not directed to children under 13, and we do not knowingly '
          'collect personal information from children under 13. A parent or '
          'guardian who believes a child provided information should contact '
          'us so we can review and delete it.',
    ),
    (
      title: '11. Changes to this policy',
      body:
          'We may update this policy when our practices or legal obligations '
          'change. The current version and effective date will remain '
          'available at www.sora-eg.store/privacy_policy.',
    ),
    (
      title: '12. Contact us',
      body:
          'For privacy questions or requests, email support@sora-eg.store or '
          'call +20 111 105 8359.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('privacy_policy'.tr)),
      body: SelectionArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 860),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 48),
              children: [
                Text(
                  'Sora Privacy Policy',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppConstants.darkBeige,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Effective date: July 20, 2026',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppConstants.mediumBeige,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Your privacy matters to us. Please read this policy to '
                  'understand what information Sora handles and the choices '
                  'available to you.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(height: 1.55),
                ),
                const SizedBox(height: 24),
                for (final section in _sections) ...[
                  Text(
                    section.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    section.body,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(height: 1.55),
                  ),
                  const SizedBox(height: 24),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
