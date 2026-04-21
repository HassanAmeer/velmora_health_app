// import 'package:velmora/screens/home/navigation_bar.dart';
// import 'package:velmora/utils/responsive_sizer.dart';
// import 'package:flutter/material.dart';

// class LogInScreen extends StatelessWidget {
//   const LogInScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     // Define the primary purple color from the image
//     const Color primaryPurple = Color.fromARGB(255, 120, 42, 245);
//     const Color lightPurpleBorder = Color(0xFFE8E1FF);
//     const Color greyText = Color(0xFF757575);

//     return Scaffold(
//       backgroundColor: const Color(
//         0xFFFDF7FF,
//       ), // Light pinkish-white background
//       body: Center(
//         child: SingleChildScrollView(
//           padding: EdgeInsets.symmetric(horizontal: 24.w),
//           child: Card(
//             elevation: 10,

//             shadowColor: Colors.black12,
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(30.adaptSize),
//             ),
//             child: Padding(
//               padding: EdgeInsets.all(32.adaptSize),
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Text(
//                     'Log In',
//                     style: TextStyle(
//                       fontSize: 28.fSize,
//                       fontWeight: FontWeight.w600,
//                       color: Color(0xFF4A148C), // Dark purple title
//                     ),
//                   ),
//                   SizedBox(height: 32.h),

//                   // Email Field
//                   _buildTextField(
//                     hintText: 'Enter your email',
//                     icon: Icons.email_outlined,
//                     borderColor: lightPurpleBorder,
//                   ),
//                   const SizedBox(height: 16),

//                   // Password Field
//                   _buildTextField(
//                     hintText: 'Enter your password',
//                     icon: Icons.lock_outline,
//                     borderColor: lightPurpleBorder,
//                     obscureText: true,
//                   ),
//                   const SizedBox(height: 24),

//                   // Log In Button
//                   SizedBox(
//                     width: double.infinity,
//                     height: 55,
//                     child: ElevatedButton(
//                       onPressed: () {
//                         Navigator.pushReplacement(
//                           context,
//                           MaterialPageRoute(
//                             builder: (context) => MainNavigationWrapper(),
//                           ),
//                         );
//                       },
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: primaryPurple,
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(15),
//                         ),
//                         elevation: 5,
//                       ),
//                       child: const Text(
//                         'Log In',
//                         style: TextStyle(
//                           fontSize: 18,
//                           color: Colors.white,
//                           fontWeight: FontWeight.w500,
//                         ),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(height: 24),

//                   // OR Divider
//                   Row(
//                     children: [
//                       Expanded(
//                         child: Divider(color: lightPurpleBorder, thickness: 1),
//                       ),
//                       const Padding(
//                         padding: EdgeInsets.symmetric(horizontal: 10),
//                         child: Text(
//                           'or',
//                           style: TextStyle(color: primaryPurple),
//                         ),
//                       ),
//                       Expanded(
//                         child: Divider(color: lightPurpleBorder, thickness: 1),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 24),

//                   // Google Button
//                   _buildSocialButton(
//                     label: 'Continue with Google',
//                     icon: Icons
//                         .chrome_reader_mode_outlined, // Placeholder for Google G icon
//                     borderColor: lightPurpleBorder,
//                   ),
//                   const SizedBox(height: 16),

//                   // Apple Button
//                   _buildSocialButton(
//                     label: 'Continue with Apple',
//                     icon: Icons.apple,
//                     borderColor: lightPurpleBorder,
//                   ),
//                   const SizedBox(height: 32),

//                   // Footer link
//                   TextButton(
//                     onPressed: () {},
//                     child: const Text(
//                       "Don't have an account?",
//                       style: TextStyle(
//                         color: primaryPurple,
//                         fontWeight: FontWeight.bold,
//                         fontSize: 16,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildTextField({
//     required String hintText,
//     required IconData icon,
//     required Color borderColor,
//     bool obscureText = false,
//   }) {
//     return TextField(
//       obscureText: obscureText,
//       decoration: InputDecoration(
//         hintText: hintText,
//         hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
//         prefixIcon: Icon(icon, color: const Color(0xFFA28CFF), size: 20),
//         filled: true,
//         fillColor: const Color(0xFFF9F8FF),
//         contentPadding: const EdgeInsets.symmetric(vertical: 18),
//         enabledBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(15),
//           borderSide: BorderSide(color: borderColor),
//         ),
//         focusedBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(15),
//           borderSide: const BorderSide(color: Color(0xFF7B2FF7), width: 1.5),
//         ),
//       ),
//     );
//   }

//   Widget _buildSocialButton({
//     required String label,
//     required IconData icon,
//     required Color borderColor,
//   }) {
//     return SizedBox(
//       width: double.infinity,
//       height: 55,
//       child: OutlinedButton.icon(
//         onPressed: () {},
//         icon: Icon(icon, color: Colors.black87, size: 22),
//         label: Text(
//           label,
//           style: const TextStyle(color: Colors.black87, fontSize: 15),
//         ),
//         style: OutlinedButton.styleFrom(
//           side: BorderSide(color: borderColor),
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(15),
//           ),
//           backgroundColor: const Color(0xFFF9F8FF),
//         ),
//       ),
//     );
//   }
// }
