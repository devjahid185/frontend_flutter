import 'package:flutter/material.dart';

import '../common/modern_app_bar.dart';

class TermsPrivacyScreen extends StatelessWidget {
  const TermsPrivacyScreen({super.key});

  static const _effectiveDate = 'Effective date: September 24, 2026';

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: const ModernAppBar(
        title: 'Terms & Privacy',
        subtitle: 'Bholavashi by Sohoj IT',
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        children: [
          _HeaderCard(scheme: scheme),
          const SizedBox(height: 14),
          _PolicySection(
            title: 'Privacy Policy',
            caption: _effectiveDate,
            paragraphs: const [
              'Bholavashi is a local digital service platform operated by Sohoj IT. This Privacy Policy explains how we collect, use, store, share and protect information when you use the Bholavashi mobile app, website and related services.',
              'We collect only the information needed to provide and secure features such as account login, local service listings, food and medicine orders, rider delivery, restaurant owner tools, support, notifications, reviews and order tracking.',
              'If you do not use a feature, data related to that feature may not be collected from you.',
            ],
            bullets: const [
              'Account information: name, phone number, email address, profile photo and basic address details.',
              'Order and service information: food and medicine orders, delivery address, saved addresses, booking/listing details, support requests, reviews and transaction status.',
              'Payment and financial records: item totals, delivery fees, discounts, payment method, manual bKash/Nagad transaction ID, payment proof, cash-on-delivery status and settlement records.',
              'Health-related service information: medicine order details, prescription-related notes, blood donor/request details, doctor appointment details and related user-provided notes.',
              'Location information: current or selected location for delivery, restaurant/rider routing and live order tracking when a delivery is active.',
              'Device and notification information: device token, app version and basic technical logs used for push notifications, fraud prevention and troubleshooting.',
              'Media, files and documents: photos or files that you choose to upload, such as profile photos, food images, KYC documents, support attachments, payment proof or delivery proof.',
              'App activity and analytics information: app interactions, searches, deep links, cart/order actions, reviews, support messages and SDK events where enabled.',
              'Login and security information: OTP verification, Google sign-in identifiers, active device records, IP-based security logs and account deletion request records.',
            ],
          ),
          const SizedBox(height: 12),
          const _PolicySection(
            title: 'How We Use Information',
            paragraphs: [
              'We use information to create and secure accounts, verify OTP or Google login, process orders, calculate delivery charges, apply discounts, assign riders, manage owner/rider workflows, provide support, send important notifications, prevent fraud and improve app reliability.',
              'Location data is used for selected delivery locations, distance calculation, rider matching, live delivery tracking and route visibility. Location access is requested only when you choose a location-based feature or when a rider uses delivery features. We do not sell your location data.',
              'Uploaded photos, files and documents are used only for the feature where they are submitted, such as KYC verification, product/restaurant listing, support, payment proof or delivery proof.',
            ],
          ),
          const SizedBox(height: 12),
          const _PolicySection(
            title: 'Sharing and Third-Party Services',
            paragraphs: [
              'We share only the information needed to provide the requested service. For example, restaurants may receive order and delivery details, riders may receive delivery contact/location information, and support/admin teams may access records needed to resolve issues or keep the platform safe.',
              'The app may use trusted third-party services such as Google Maps and routing services, Firebase Cloud Messaging, Google sign-in, Meta App Events, payment or SMS/email gateways, hosting/database and media storage providers. These services process data according to their own privacy and security practices.',
              'We do not sell personal data and do not share data for unrelated third-party resale.',
            ],
          ),
          const SizedBox(height: 12),
          const _PolicySection(
            title: 'Permissions and Optional Access',
            paragraphs: [
              'The app may request notification permission for order updates, rider requests, support updates and important service alerts.',
              'The app may request approximate or precise location permission when you select current location, delivery location, restaurant location, rider delivery routing or live tracking features.',
              'The app may allow you to choose images or files for profile photos, food/restaurant images, rider KYC, support attachments, payment proof or delivery proof. These uploads are user initiated.',
            ],
          ),
          const SizedBox(height: 12),
          const _PolicySection(
            title: 'Data We Do Not Collect From the Device',
            paragraphs: [
              'Based on the current app implementation, Bholavashi does not request or collect contacts, SMS/MMS message content, call logs, calendar data, microphone/audio recordings, installed apps list or web browsing history from your device.',
              'If a future version adds a new sensitive permission or data type, this policy and the Google Play Data safety declaration will be updated before or with that release.',
            ],
          ),
          const SizedBox(height: 12),
          const _PolicySection(
            title: 'Data Security and Retention',
            paragraphs: [
              'We use HTTPS for data in transit and reasonable technical and administrative safeguards to protect user data. However, no online service can guarantee absolute security.',
              'We retain information only as long as needed for account management, service delivery, legal/accounting obligations, rider and restaurant settlement, safety, fraud prevention, dispute resolution and operational purposes.',
              'Some transaction, payout, fraud-prevention or legal records may be retained even after account deletion if required for legitimate business, tax, accounting, safety or legal reasons.',
            ],
          ),
          const SizedBox(height: 12),
          const _PolicySection(
            title: 'Children and Sensitive Use',
            paragraphs: [
              'Bholavashi is not intended for children under 13. If we learn that we have collected personal information from a child without appropriate consent, we will take reasonable steps to delete it.',
            ],
          ),
          const SizedBox(height: 14),
          const _PolicySection(
            title: 'Terms of Service',
            caption: _effectiveDate,
            paragraphs: [
              'By using Bholavashi, you agree to use the app lawfully, provide accurate information and follow the rules applicable to each service.',
              'Users must not misuse the app, create fake orders, upload harmful content, attempt unauthorized access, harass others, interfere with delivery operations or violate local laws.',
            ],
            bullets: [
              'Food orders, delivery charges, cancellation rules and refunds may vary based on restaurant, rider availability, payment method and operational conditions.',
              'Restaurant owners, riders and service providers are responsible for keeping their profile, availability, pricing, KYC and service information accurate.',
              'Sohoj IT may suspend or restrict accounts that are fraudulent, unsafe, abusive or harmful to the platform, customers, riders or partners.',
              'Service availability may change due to network issues, maintenance, weather, local conditions, business hours or other operational reasons.',
            ],
          ),
          const SizedBox(height: 12),
          const _PolicySection(
            title: 'Payments, Orders and Cancellations',
            paragraphs: [
              'Users are responsible for paying applicable product prices, delivery fees, service charges or other approved charges shown before or during service confirmation.',
              'Cancellation, refund and payout decisions may depend on order status, preparation status, delivery progress, payment method and partner policies.',
            ],
          ),
          const SizedBox(height: 12),
          const _PolicySection(
            title: 'Changes and Contact',
            paragraphs: [
              'We may update these Terms and Privacy Policy from time to time. Updated versions will be available inside the app and on our website.',
              'Users can request account deletion or data deletion from inside the app or through https://bholavashi.site/delete-account/. For privacy questions, support, account deletion or policy concerns, contact Sohoj IT through the Help & Support section of the app or by email at support@bholavashi.site.',
            ],
          ),
          const SizedBox(height: 14),
          _FooterCard(scheme: scheme),
        ],
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.34),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bholavashi Policies',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            'Clear rules for privacy, safety, local services, delivery and responsible platform use.',
            style: TextStyle(
              color: scheme.onSurfaceVariant,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Company: Sohoj IT\nProduct: Bholavashi\nWebsite: https://bholavashi.site/privacy-policy',
            style: TextStyle(color: scheme.onSurfaceVariant, height: 1.45),
          ),
        ],
      ),
    );
  }
}

class _PolicySection extends StatelessWidget {
  const _PolicySection({
    required this.title,
    required this.paragraphs,
    this.caption,
    this.bullets = const [],
  });

  final String title;
  final String? caption;
  final List<String> paragraphs;
  final List<String> bullets;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          if (caption != null) ...[
            const SizedBox(height: 4),
            Text(
              caption!,
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
            ),
          ],
          const SizedBox(height: 10),
          ...paragraphs.map(
            (text) => Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: Text(
                text,
                style: TextStyle(color: scheme.onSurfaceVariant, height: 1.5),
              ),
            ),
          ),
          ...bullets.map(
            (text) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.only(top: 8),
                    decoration: BoxDecoration(
                      color: scheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      text,
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FooterCard extends StatelessWidget {
  const _FooterCard({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Powered by Sohoj IT • support@bholavashi.site',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: scheme.onSurfaceVariant,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
