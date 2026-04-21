import 'package:velmora/constants/app_colors.dart';
import 'package:velmora/utils/responsive_sizer.dart';
import 'package:velmora/screens/legal/privacy_policy_screen.dart';
import 'package:velmora/screens/legal/terms_of_service_screen.dart';
import 'package:velmora/services/admin_service.dart';
import 'package:velmora/l10n/app_localizations.dart';
import 'package:velmora/widgets/app_loading_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  final AdminService _adminService = AdminService();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FF),
      body: Column(
        children: [
          _buildHeader(context, l10n),
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
              children: [
                _buildSectionTitle(l10n.translate('get_help')),
                SizedBox(height: 12.h),
                _buildHelpGroup(context, [
                  _buildHelpItem(
                    context,
                    l10n.translate('faqs'),
                    l10n.translate('find_answers_to_common_questions'),
                    Icons.help_outline,
                    () => _showFAQs(context),
                  ),
                  _buildHelpItem(
                    context,
                    l10n.contactSupport,
                    l10n.translate('get_in_touch_with_our_team'),
                    Icons.email_outlined,
                    () => _showContactSupport(context),
                  ),
                  _buildHelpItem(
                    context,
                    l10n.reportBug,
                    l10n.translate('help_us_improve_the_app'),
                    Icons.bug_report_outlined,
                    () => _showReportBug(context),
                  ),
                ]),
                SizedBox(height: 24.h),
                _buildSectionTitle(l10n.translate('resources')),
                SizedBox(height: 12.h),
                _buildHelpGroup(context, [
                  _buildHelpItem(
                    context,
                    l10n.termsOfService,
                    l10n.translate('read_our_terms_and_conditions'),
                    Icons.description_outlined,
                    () => _showTerms(context),
                  ),
                  _buildHelpItem(
                    context,
                    l10n.privacyPolicy,
                    l10n.translate('how_we_handle_your_data'),
                    Icons.privacy_tip_outlined,
                    () => _showPrivacyPolicy(context),
                  ),
                ]),
                SizedBox(height: 24.h),
                _buildSectionTitle(l10n.about),
                SizedBox(height: 12.h),
                _buildAboutCard(),
                SizedBox(height: 100.h),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppLocalizations l10n) {
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
            l10n.helpSupport,
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

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 14.fSize,
        fontWeight: FontWeight.w600,
        color: Colors.grey.shade600,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildHelpGroup(BuildContext context, List<Widget> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.adaptSize),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(children: items),
    );
  }

  Widget _buildHelpItem(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20.adaptSize),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 18.h),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10.adaptSize),
              decoration: BoxDecoration(
                color: AppColors.brandPurple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12.adaptSize),
              ),
              child: Icon(
                icon,
                color: AppColors.brandPurple,
                size: 22.adaptSize,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16.fSize,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12.fSize,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.grey.shade400,
              size: 24.adaptSize,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutCard() {
    return Container(
      padding: EdgeInsets.all(24.adaptSize),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.adaptSize),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Image.asset(
                'assets/splash_logo.png',
                width: MediaQuery.of(context).size.width * 0.5,
                color: Colors.deepPurpleAccent,
                colorBlendMode: BlendMode.srcIn,
              )
              .animate(onPlay: (controller) => controller.repeat())
              .shimmer(
                color: Colors.yellow,
                duration: const Duration(seconds: 2),
              ),
          SizedBox(height: 8.h),
          Text(
            '${AppLocalizations.of(context).version} 1.0.0',
            style: TextStyle(fontSize: 14.fSize, color: Colors.grey.shade600),
          ),
          SizedBox(height: 16.h),
          Text(
            AppLocalizations.of(
              context,
            ).translate('strengthening_relationships_through_wellness'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.fSize,
              color: Colors.grey.shade600,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  void _showFAQs(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => FutureBuilder<List<Map<String, dynamic>>>(
        future: _adminService.getFAQs(),
        builder: (context, snapshot) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(l10n.translate('frequently_asked_questions')),
            content: snapshot.connectionState == ConnectionState.waiting
                ? SizedBox(
                    height: 100.h,
                    child: const Center(child: AppCircularLoader()),
                  )
                : snapshot.hasError ||
                      !snapshot.hasData ||
                      snapshot.data!.isEmpty
                ? Text(l10n.translate('no_faqs_available_at_the_moment'))
                : SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: snapshot.data!
                          .map(
                            (faq) => Padding(
                              padding: EdgeInsets.only(bottom: 16.h),
                              child: _buildFAQItem(
                                faq['question'] ?? '',
                                faq['answer'] ?? '',
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.close),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question,
          style: TextStyle(
            fontSize: 14.fSize,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          answer,
          style: TextStyle(fontSize: 13.fSize, color: Colors.grey.shade700),
        ),
      ],
    );
  }

  void _showContactSupport(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final TextEditingController nameController = TextEditingController();
    final TextEditingController emailController = TextEditingController();
    final TextEditingController messageController = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(l10n.contactSupport),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.translate(
                    'send_us_a_message_and_well_get_back_to_you_soon',
                  ),
                ),
                SizedBox(height: 16.h),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: l10n.name,
                    border: const OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 12.h),
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: l10n.email,
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                SizedBox(height: 12.h),
                TextField(
                  controller: messageController,
                  decoration: InputDecoration(
                    labelText: l10n.translate('message'),
                    border: const OutlineInputBorder(),
                  ),
                  maxLines: 4,
                ),
                if (isSubmitting) ...[
                  SizedBox(height: 16.h),
                  const Center(child: AppCircularLoader()),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.pop(context),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      if (nameController.text.isEmpty ||
                          emailController.text.isEmpty ||
                          messageController.text.isEmpty) {
                        return;
                      }
                      setDialogState(() => isSubmitting = true);
                      try {
                        await _adminService.submitSupportMessage(
                          name: nameController.text,
                          email: emailController.text,
                          message: messageController.text,
                        );
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(l10n.translate('message_sent')),
                            ),
                          );
                        }
                      } catch (e) {
                        setDialogState(() => isSubmitting = false);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('${l10n.error}: $e')),
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandPurple,
              ),
              child: Text(
                l10n.translate('send'),
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showReportBug(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final TextEditingController titleController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(l10n.reportBug),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l10n.translate('help_us_improve_the_app')),
                SizedBox(height: 16.h),
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: l10n.translate('bug_title'),
                    border: const OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 12.h),
                TextField(
                  controller: descriptionController,
                  decoration: InputDecoration(
                    labelText: l10n.translate('description'),
                    hintText: l10n.translate('please_describe_what_happened'),
                    border: const OutlineInputBorder(),
                  ),
                  maxLines: 5,
                ),
                if (isSubmitting) ...[
                  SizedBox(height: 16.h),
                  const Center(child: AppCircularLoader()),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.pop(context),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      if (titleController.text.isEmpty ||
                          descriptionController.text.isEmpty) {
                        return;
                      }
                      setDialogState(() => isSubmitting = true);
                      try {
                        await _adminService.submitBugReport(
                          title: titleController.text,
                          description: descriptionController.text,
                        );
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                l10n.translate('bug_report_submitted'),
                              ),
                            ),
                          );
                        }
                      } catch (e) {
                        setDialogState(() => isSubmitting = false);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('${l10n.error}: $e')),
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandPurple,
              ),
              child: Text(
                l10n.translate('submit'),
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTerms(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TermsOfServiceScreen()),
    );
  }

  void _showPrivacyPolicy(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PrivacyPolicyScreen()),
    );
  }
}
