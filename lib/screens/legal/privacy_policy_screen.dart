import 'package:velmora/services/admin_service.dart';
import 'package:flutter/material.dart';
import 'package:velmora/constants/app_colors.dart';
import 'package:velmora/l10n/app_localizations.dart';
import 'package:velmora/utils/responsive_sizer.dart';
import 'package:velmora/widgets/skeletons/legal_skeleton.dart';

class PrivacyPolicyScreen extends StatefulWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {
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
              future: _adminService.getLegalDoc('privacy_policy'),
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
        'title': 'Introduction',
        'content':
            'Velmora AI ("we", "our", or "us") is committed to protecting your privacy. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our mobile application.',
      },
      {
        'title': 'Information We Collect',
        'content':
            'We collect information that you provide directly to us, including:\n\n'
            '• Account information (email, name, profile picture)\n'
            '• User-generated content (chat messages, game responses)\n'
            '• Health and wellness data (exercise tracking)\n'
            '• Device information and usage data\n'
            '• Analytics and performance data',
      },
      {
        'title': 'How We Use Your Information',
        'content':
            'We use the information we collect to:\n\n'
            '• Provide and maintain our services\n'
            '• Personalize your experience\n'
            '• Improve our AI responses and features\n'
            '• Send you notifications and updates\n'
            '• Analyze usage patterns and improve the app\n'
            '• Comply with legal obligations',
      },
      {
        'title': 'Data Security',
        'content':
            'We implement industry-standard security measures to protect your data:\n\n'
            '• End-to-end encryption for sensitive data\n'
            '• Secure cloud storage with Firebase\n'
            '• Regular security audits\n'
            '• Limited employee access to user data\n'
            '• Biometric authentication options',
      },
      {
        'title': 'AI and Data Processing',
        'content':
            'When you interact with our AI features:\n\n'
            '• Messages are processed through secure Firebase Cloud Functions\n'
            '• API keys are never stored in the mobile app\n'
            '• Personal identifiers are anonymized before AI processing\n'
            '• Conversation context is cached temporarily for better responses\n'
            '• You can delete your chat history at any time',
      },
      {
        'title': 'Third-Party Services',
        'content':
            'We use the following third-party services:\n\n'
            '• Firebase (Google) - Authentication, database, analytics\n'
            '• Google Gemini AI - AI-powered responses\n'
            '• App Store / Google Play - Payment processing\n\n'
            'These services have their own privacy policies governing their use of your information.',
      },
      {
        'title': 'Your Rights (GDPR)',
        'content':
            'Under GDPR, you have the right to:\n\n'
            '• Access your personal data\n'
            '• Rectify inaccurate data\n'
            '• Request deletion of your data\n'
            '• Export your data\n'
            '• Withdraw consent at any time\n'
            '• Lodge a complaint with a supervisory authority\n\n'
            'To exercise these rights, contact us at privacy@velmora.com',
      },
      {
        'title': 'Data Retention',
        'content':
            'We retain your data for as long as your account is active or as needed to provide services. When you delete your account:\n\n'
            '• Personal data is permanently deleted within 30 days\n'
            '• Anonymized analytics data may be retained\n'
            '• Backup copies are deleted within 90 days',
      },
      {
        'title': 'Children\'s Privacy',
        'content':
            'Our service is not intended for users under 18 years of age. We do not knowingly collect personal information from children. If you believe we have collected information from a child, please contact us immediately.',
      },
      {
        'title': 'International Data Transfers',
        'content':
            'Your information may be transferred to and processed in countries other than your own. We ensure appropriate safeguards are in place to protect your data in accordance with this Privacy Policy.',
      },
      {
        'title': 'Changes to This Policy',
        'content':
            'We may update this Privacy Policy from time to time. We will notify you of any changes by posting the new policy in the app and updating the "Last Updated" date.',
      },
      {
        'title': 'Contact Us',
        'content':
            'If you have questions about this Privacy Policy, please contact us:\n\n'
            'Email: privacy@velmora.com\n'
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
            l10n.privacyPolicy,
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
