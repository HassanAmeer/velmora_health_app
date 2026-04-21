import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  // 1. Setup controllers and keys
  final _emailController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  // 2. Define the Firebase Password Reset function
  Future<void> _sendPasswordResetEmail() async {
    if (!_formKey.currentState!.validate()) {
      return; // Do not proceed if the form is invalid
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // THE CORE FIREBASE FUNCTIONALITY:
      await _auth.sendPasswordResetEmail(email: _emailController.text.trim());

      // Success Feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Password reset link sent! Check your email.',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Color(0xFF00E5FF), // Teal/Cyan accent
            behavior: SnackBarBehavior.floating,
          ),
        );
        // Optional: Navigate back to login
        // Navigator.of(context).pop();
      }
    } on FirebaseAuthException catch (e) {
      // Error Handling: Handle specific Firebase errors
      String errorMessage;
      if (e.code == 'user-not-found') {
        errorMessage = 'No user found with this email.';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'The email address is invalid.';
      } else {
        errorMessage = 'An error occurred. Please try again later.';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              errorMessage,
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: const Color(0xFFFF00D4), // Magenta accent
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      // Catch any non-Firebase specific errors
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('An unexpected error occurred.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Styling constants derived from the AI theme
    const darkBlueBg = Color(0xFF01123D);
    const deepPurple = Color(0xFF6200EA);
    const neonCyan = Color(0xFF00E5FF);
    const glowGradient = RadialGradient(
      center: Alignment.topLeft,
      radius: 1.5,
      colors: [Colors.black, deepPurple, darkBlueBg],
      stops: [0.0, 0.5, 1.0],
    );

    return Scaffold(
      backgroundColor: darkBlueBg,
      body: Container(
        // Applying the high-tech AI glowing background
        decoration: const BoxDecoration(gradient: glowGradient),
        child: Column(
          children: [
            // 3. High-Tech Visual Banner (Inspired by Velmora AI)
            Stack(
              children: [
                Container(
                  height: 250,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(50),
                      bottomRight: Radius.circular(50),
                    ),
                  ),
                ),
                Positioned(
                  top: 120,
                  left: 0,
                  right: 0,
                  child: Column(
                    children: [
                      // Central Icon with glowing effect
                      Image.asset(
                        'assets/splash_logo.png',
                        width: MediaQuery.of(context).size.width * 0.3,
                        color: Colors.white,
                        colorBlendMode: BlendMode.srcIn,
                      ),
                    ],
                  ),
                ),
                // Back Button
                Positioned(
                  top: 50,
                  left: 20,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white12,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white12),
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_new,
                        color: Colors.white70,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ),
              ],
            ),

            // 4. Form and Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(30.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      const Text(
                        'Forgot your password?',
                        style: TextStyle(
                          fontSize: 22,
                          color: Colors.white70,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Enter the email address associated with your account. We\'ll send you a temporary link to reset your password.',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.5),
                        ),
                      ),
                      const SizedBox(height: 50),

                      // 5. Email Input Field (Styled for AI/Tech)
                      TextFormField(
                        controller: _emailController,
                        style: const TextStyle(color: Colors.white),
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          hintText: 'your_ai@email.com',
                          hintStyle: TextStyle(
                            color: Colors.white.withOpacity(0.3),
                          ),
                          filled: true,
                          fillColor: const Color(0xFF03194A).withOpacity(0.5),
                          prefixIcon: const Icon(Icons.email, color: neonCyan),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15.0),
                            borderSide: const BorderSide(
                              color: neonCyan,
                              width: 2.0,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15.0),
                            borderSide: const BorderSide(
                              color: Color(0xFF132D65),
                            ),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15.0),
                            borderSide: const BorderSide(
                              color: Color(0xFFFF00D4),
                            ),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15.0),
                            borderSide: const BorderSide(
                              color: Color(0xFFFF00D4),
                              width: 2.0,
                            ),
                          ),
                        ),
                        // 6. Form Validation
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter an email address';
                          }
                          // Simple Regex for email validation
                          if (!RegExp(
                            r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
                          ).hasMatch(value)) {
                            return 'Enter a valid email address';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 60),

                      // 7. Dynamic Action Button
                      _isLoading
                          ? const Center(
                              child: CircularProgressIndicator(color: neonCyan),
                            )
                          : Container(
                              width: double.infinity,
                              height: 60,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                gradient: const LinearGradient(
                                  colors: [
                                    neonCyan,
                                    Color(0xFF00CBEF),
                                  ], // Cyan to teal gradient
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: neonCyan.withOpacity(0.3),
                                    blurRadius: 15,
                                    offset: const Offset(0, 5),
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: _sendPasswordResetEmail,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                child: const Text(
                                  'SEND RESET LINK',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: darkBlueBg,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ),
                            ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
