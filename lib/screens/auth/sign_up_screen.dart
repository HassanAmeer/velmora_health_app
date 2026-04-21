import 'dart:io' show Platform;
import 'package:flutter/gestures.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:velmora/constants/app_colors.dart';
import 'package:velmora/screens/auth/sign_in_screen.dart';
import 'package:velmora/widgets/bottom_nav_bar_widget.dart';
import 'package:velmora/services/auth_service.dart';
import 'package:velmora/utils/responsive_sizer.dart';
import 'package:velmora/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:velmora/widgets/app_loading_widgets.dart';
import 'package:velmora/screens/settings/help_support_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _isAppleLoading = false;
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    final l10n = AppLocalizations.of(context);
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showErrorSnackbar('${l10n.signIn}: ${l10n.email} & ${l10n.password}');
      return;
    }

    if (password.length < 6) {
      _showErrorSnackbar('Password must be at least 6 characters');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _authService.signUpWithEmailPassword(
        email: email,
        password: password,
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const BottomNavBarWidget()),
        );
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackbar(e.toString());
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        action: message.toLowerCase().contains('banned')
            ? SnackBarAction(
                label: 'Contact',
                textColor: Colors.white,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const HelpSupportScreen(),
                    ),
                  );
                },
              )
            : null,
      ),
    );
  }

  Future<void> _handleGoogleSignIn() async {
    if (_isGoogleLoading || _isAppleLoading || _isLoading) return;

    setState(() {
      _isGoogleLoading = true;
    });

    try {
      final userCredential = await _authService.signInWithGoogle();

      if (userCredential == null) {
        // User canceled
        if (mounted) {
          setState(() {
            _isGoogleLoading = false;
          });
        }
        return;
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const BottomNavBarWidget()),
        );
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackbar(e.toString());
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGoogleLoading = false;
        });
      }
    }
  }

  Future<void> _handleAppleSignIn() async {
    if (_isGoogleLoading || _isAppleLoading || _isLoading) return;

    setState(() {
      _isAppleLoading = true;
    });

    try {
      final userCredential = await _authService.signInWithApple();

      if (userCredential == null) {
        // User canceled
        if (mounted) {
          setState(() {
            _isAppleLoading = false;
          });
        }
        return;
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const BottomNavBarWidget()),
        );
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackbar(e.toString());
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAppleLoading = false;
        });
      }
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.bgGradientStart, AppColors.white],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              children: [
                SizedBox(height: 60.h),
                // const TogetherLogo(),
                Image.asset(
                  'assets/splash_logo.png',
                  width: MediaQuery.of(context).size.width * 0.3,
                  color: Colors.deepPurpleAccent,
                  colorBlendMode: BlendMode.srcIn,
                ),

                SizedBox(height: 14.h),
                Text(
                  'Together',
                  style: TextStyle(
                    fontSize: 32.fSize,
                    fontWeight: FontWeight.w600,
                    color: AppColors.brandPurpleDark,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  l10n.wellnessForCouples,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                SizedBox(height: 30.h),

                // --- LOGIN CARD ---
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.cardShadow,
                        blurRadius: 20,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        l10n.signUp,
                        style: TextStyle(
                          fontSize: 24.fSize,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 20.fSize),

                      _buildTextField(
                        hint: l10n.email,
                        icon: Icons.email_outlined,
                        controller: _emailController,
                      ),
                      const SizedBox(height: 16),

                      _buildTextField(
                        hint: l10n.password,
                        icon: Icons.lock_outline,
                        isPassword: true,
                        controller: _passwordController,
                      ),

                      SizedBox(height: 20.h),

                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleSignUp,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.brandPurple,
                            foregroundColor: AppColors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: _isLoading
                              ? const AppCircularLoader(
                                  size: 20,
                                  strokeWidth: 2,
                                  color: Colors.white,
                                )
                              : Text(
                                  l10n.signUp,
                                  style: TextStyle(
                                    fontSize: 16.fSize,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                      SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                text: 'I agree to the ',
                                style: const TextStyle(color: Colors.black87),
                                children: [
                                  TextSpan(
                                    text: 'Privacy Policy',
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      decoration: TextDecoration.underline,
                                    ),
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = () {
                                        _launchUrl(
                                          'https://velmora-ai.com/privacy',
                                        );
                                      },
                                  ),
                                  const TextSpan(text: ' & '),
                                  TextSpan(
                                    text: 'Terms of Use',
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      decoration: TextDecoration.underline,
                                    ),
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = () {
                                        _launchUrl(
                                          'https://velmora-ai.com/terms',
                                        );
                                      },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10.h),

                      Row(
                        children: [
                          const Expanded(
                            child: Divider(color: AppColors.inputBorder),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              l10n.orContinueWith,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                          const Expanded(
                            child: Divider(color: AppColors.inputBorder),
                          ),
                        ],
                      ),
                      SizedBox(height: 20.h),

                      _buildSocialButton(
                        label: '${l10n.orContinueWith} ${l10n.google}',
                        iconPath: Icons.g_mobiledata,
                        isLoading: _isGoogleLoading,
                        onTap:
                            (_isGoogleLoading || _isAppleLoading || _isLoading)
                            ? null
                            : _handleGoogleSignIn,
                      ),
                      SizedBox(height: 12.h),
                      if (Platform.isIOS)
                        _buildSocialButton(
                          label: '${l10n.orContinueWith} ${l10n.apple}',
                          iconPath: Icons.apple,
                          isLoading: _isAppleLoading,
                          onTap:
                              (_isGoogleLoading ||
                                  _isAppleLoading ||
                                  _isLoading)
                              ? null
                              : _handleAppleSignIn,
                        ),
                      SizedBox(height: 20.h),

                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LogInScreen(),
                            ),
                          );
                        },
                        child: Text(
                          l10n.alreadyHaveAccount,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14.fSize,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 30.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String hint,
    required IconData icon,
    bool isPassword = false,
    TextEditingController? controller,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword && !_isPasswordVisible,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.hintText, fontSize: 14),
        prefixIcon: Icon(icon, color: AppColors.brandPurpleLight, size: 22),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                  color: AppColors.hintText,
                  size: 22,
                ),
                onPressed: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
                  });
                },
              )
            : null,
        filled: true,
        fillColor: AppColors.inputFill,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 18,
          horizontal: 16,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: AppColors.brandPurple,
            width: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required String label,
    required IconData iconPath,
    required bool isLoading,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 54,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.inputBorder),
          borderRadius: BorderRadius.circular(16),
          color: onTap == null ? Colors.grey.shade100 : AppColors.inputFill,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading)
              const AppCircularLoader(size: 20, strokeWidth: 2)
            else ...[
              Icon(iconPath, size: 24),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class TogetherLogo extends StatelessWidget {
  const TogetherLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 60.w,
      height: 40.h,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 0,
            child: Icon(
              Icons.favorite,
              color: Color.fromARGB(255, 175, 144, 231),
              size: 30.fSize,
            ),
          ),
          Positioned(
            right: 0,
            child: Icon(
              Icons.favorite,
              color: Color.fromARGB(255, 99, 59, 100),
              size: 30.fSize,
            ),
          ),
        ],
      ),
    );
  }
}
