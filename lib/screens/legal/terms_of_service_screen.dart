import 'package:velmora/services/admin_service.dart';
import 'package:flutter/material.dart';
import 'package:velmora/constants/app_colors.dart';
import 'package:velmora/l10n/app_localizations.dart';
import 'package:velmora/utils/responsive_sizer.dart';
import 'package:velmora/widgets/skeletons/legal_skeleton.dart';

class TermsOfServiceScreen extends StatefulWidget {
  const TermsOfServiceScreen({super.key});

  @override
  State<TermsOfServiceScreen> createState() => _TermsOfServiceScreenState();
}

class _TermsOfServiceScreenState extends State<TermsOfServiceScreen> {
  final AdminService _adminService = AdminService();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FF),
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: FutureBuilder<Map<String, dynamic>?>(
              future: _adminService.getLegalDoc('terms_of_service'),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LegalScreenSkeleton();
                }

                final data = snapshot.data;
                final List<dynamic> sections =
                    data?['sections'] ?? _getFallbackSections();
                final String lastUpdated =
                    data?['lastUpdated'] ?? 'February 26, 2026';

                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.symmetric(
                    horizontal: 24.w,
                    vertical: 24.h,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ...sections.map(
                        (section) => Padding(
                          padding: EdgeInsets.only(bottom: 24.h),
                          child: _buildSection(
                            section['title'] ?? '',
                            section['content'] ?? '',
                          ),
                        ),
                      ),
                      Center(
                        child: Text(
                          '${l10n.translate('last_updated')}: $lastUpdated',
                          style: TextStyle(
                            fontSize: 12.fSize,
                            color: Colors.grey.shade600,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                      SizedBox(height: 100.h),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, String>> _getFallbackSections() {
    return [
      {
        'title': 'Agreement to Terms',
        'content':
            'By accessing or using Velmora AI, you agree to be bound by these Terms of Service. If you do not agree to these terms, please do not use our service.',
      },
      {
        'title': 'Description of Service',
        'content':
            'Velmora AI provides:\n\n'
            '• AI-powered relationship guidance and advice\n'
            '• Interactive games for couples\n'
            '• Kegel exercise tracking and guidance\n'
            '• Chat features for communication\n'
            '• Health and wellness tools\n\n'
            'Our service is designed to support healthy relationships and intimate wellness.',
      },
      {
        'title': 'User Accounts',
        'content':
            'To use our service, you must:\n\n'
            '• Be at least 18 years of age\n'
            '• Provide accurate and complete information\n'
            '• Maintain the security of your account\n'
            '• Notify us immediately of any unauthorized access\n'
            '• Be responsible for all activities under your account',
      },
      {
        'title': 'Subscription and Payment',
        'content':
            'Free Tier:\n'
            '• Limited to 3 AI messages per day\n'
            '• Access to basic features\n\n'
            'Premium Subscription:\n'
            '• Unlimited AI messages\n'
            '• Access to all games and features\n'
            '• Monthly: \$3.99/month\n'
            '• Quarterly: \$9.99/3 months\n'
            '• Yearly: \$29.99/year\n\n'
            'Subscriptions auto-renew unless cancelled. You can cancel anytime through your App Store or Google Play account.',
      },
      {
        'title': 'Free Trial',
        'content':
            'New users receive a 48-hour free trial of Premium features. After the trial:\n\n'
            '• You will be charged unless you cancel\n'
            '• Cancel anytime during the trial period\n'
            '• No charges if cancelled before trial ends',
      },
      {
        'title': 'Refund Policy',
        'content':
            'Refunds are handled according to App Store and Google Play policies:\n\n'
            '• Contact Apple or Google for refund requests\n'
            '• We cannot process refunds directly\n'
            '• Refund eligibility determined by store policies',
      },
      {
        'title': 'Acceptable Use',
        'content':
            'You agree NOT to:\n\n'
            '• Use the service for any illegal purpose\n'
            '• Harass, abuse, or harm others\n'
            '• Share inappropriate or offensive content\n'
            '• Attempt to hack or compromise the service\n'
            '• Reverse engineer or copy our software\n'
            '• Use the service to spam or distribute malware\n'
            '• Impersonate others or provide false information',
      },
      {
        'title': 'AI-Generated Content',
        'content':
            'Important disclaimers about our AI features:\n\n'
            '• AI responses are for informational purposes only\n'
            '• Not a substitute for professional therapy or medical advice\n'
            '• We do not guarantee accuracy of AI responses\n'
            '• Always consult qualified professionals for serious issues\n'
            '• AI may occasionally produce incorrect information',
      },
      {
        'title': 'Medical Disclaimer',
        'content':
            'Velmora AI is NOT medical advice:\n\n'
            '• Kegel exercises are general wellness guidance\n'
            '• Consult healthcare providers before starting any exercise program\n'
            '• We are not responsible for health outcomes\n'
            '• Seek professional help for medical concerns',
      },
      {
        'title': 'Intellectual Property',
        'content':
            'All content, features, and functionality are owned by Velmora AI and protected by:\n\n'
            '• Copyright laws\n'
            '• Trademark laws\n'
            '• Other intellectual property rights\n\n'
            'You may not copy, modify, or distribute our content without permission.',
      },
      {
        'title': 'User Content',
        'content':
            'Content you create (messages, game responses):\n\n'
            '• You retain ownership of your content\n'
            '• You grant us license to use it to provide services\n'
            '• You are responsible for your content\n'
            '• We may remove content that violates these terms',
      },
      {
        'title': 'Privacy',
        'content':
            'Your privacy is important to us. Please review our Privacy Policy to understand how we collect, use, and protect your information.',
      },
      {
        'title': 'Termination',
        'content':
            'We may terminate or suspend your account if:\n\n'
            '• You violate these Terms of Service\n'
            '• You engage in fraudulent activity\n'
            '• Required by law\n\n'
            'You may terminate your account at any time through the app settings.',
      },
      {
        'title': 'Limitation of Liability',
        'content':
            'To the maximum extent permitted by law:\n\n'
            '• We provide the service "as is" without warranties\n'
            '• We are not liable for indirect or consequential damages\n'
            '• Our total liability is limited to the amount you paid us\n'
            '• We are not responsible for third-party services',
      },
      {
        'title': 'Indemnification',
        'content':
            'You agree to indemnify and hold us harmless from any claims, damages, or expenses arising from:\n\n'
            '• Your use of the service\n'
            '• Your violation of these terms\n'
            '• Your violation of any rights of others',
      },
      {
        'title': 'Changes to Terms',
        'content':
            'We may modify these Terms of Service at any time. We will notify you of significant changes through:\n\n'
            '• In-app notifications\n'
            '• Email notifications\n'
            '• Updated "Last Modified" date\n\n'
            'Continued use after changes constitutes acceptance.',
      },
      {
        'title': 'Governing Law',
        'content':
            'These Terms are governed by and construed in accordance with applicable laws. Any disputes will be resolved through binding arbitration.',
      },
      {
        'title': 'Contact Information',
        'content':
            'For questions about these Terms of Service:\n\n'
            'Email: legal@velmora.com\n'
            'Support: support@velmora.com',
      },
    ];
  }

  Widget _buildHeader(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Container(
      width: double.infinity,
      height: 200.h,
      decoration: const BoxDecoration(
        color: AppColors.brandPurple,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      padding: EdgeInsets.fromLTRB(24.w, 60.h, 24.w, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Icon(
              Icons.arrow_back,
              color: Colors.white,
              size: 24.adaptSize,
            ),
          ),
          SizedBox(height: 24.h),
          Text(
            l10n.termsOfService,
            style: TextStyle(
              fontSize: 32.fSize,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18.fSize,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 12.h),
        Text(
          content,
          style: TextStyle(
            fontSize: 14.fSize,
            color: Colors.grey.shade700,
            height: 1.6,
          ),
        ),
      ],
    );
  }
}
