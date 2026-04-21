import 'dart:io';
import 'package:velmora/constants/app_colors.dart';
import 'package:velmora/l10n/app_localizations.dart';
import 'package:velmora/services/auth_service.dart';
import 'package:velmora/screens/auth/sign_in_screen.dart';
import 'package:velmora/services/user_service.dart';
import 'package:velmora/utils/responsive_sizer.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:velmora/widgets/skeletons/account_skeleton.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final UserService _userService = UserService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  bool _isLoading = true;
  String? _localProfileImagePath;
  bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final userData = await _userService.getUserData();
      final prefs = await SharedPreferences.getInstance();
      final localPath = prefs.getString('local_profile_image');

      if (mounted) {
        setState(() {
          final userEmail = user?.email ?? '';
          _emailController.text = userEmail;

          final storedName = userData?['displayName'] as String?;
          _nameController.text = (storedName != null && storedName.isNotEmpty)
              ? storedName
              : (userEmail.isNotEmpty ? userEmail.split('@')[0] : '');
          _passwordController.text = userData?['password'] ?? '';
          _localProfileImagePath = localPath;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    final l10n = AppLocalizations.of(context);
    final newName = _nameController.text.trim();
    final newPassword = _passwordController.text.trim();

    if (newName.isEmpty) {
      _showSnackBar(l10n.nameCannotBeEmpty, isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      // Update display name
      await _userService.updateDisplayName(newName);

      // Update password if provided
      if (newPassword.isNotEmpty) {
        final user = FirebaseAuth.instance.currentUser;
        await user?.updatePassword(newPassword);
        await _userService.updateUserPassword(newPassword);
      }

      _showSnackBar(
        l10n.profilePictureUpdated.replaceAll("picture ", ""),
      ); // Fallback to a success message
      _passwordController.clear();
    } catch (e) {
      _showSnackBar('Failed to update profile: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showImageSourceDialog() {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(l10n.chooseProfilePicture),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(
                Icons.camera_alt,
                color: AppColors.brandPurple,
              ),
              title: Text(l10n.camera),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_library,
                color: AppColors.brandPurple,
              ),
              title: Text(l10n.gallery),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            if (_localProfileImagePath != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: Text(l10n.removePicture),
                onTap: () {
                  Navigator.pop(context);
                  _removeProfilePicture();
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final l10n = AppLocalizations.of(context);
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('local_profile_image', pickedFile.path);

      setState(() {
        _localProfileImagePath = pickedFile.path;
      });

      _showSnackBar(l10n.profilePictureUpdated);
    } catch (e) {
      _showSnackBar('${l10n.failedToUploadPicture}: $e', isError: true);
    }
  }

  Future<void> _removeProfilePicture() async {
    final l10n = AppLocalizations.of(context);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('local_profile_image');

      setState(() {
        _localProfileImagePath = null;
      });
      _showSnackBar(l10n.profilePictureRemoved);
    } catch (e) {
      _showSnackBar('${l10n.failedToRemovePicture}: $e', isError: true);
    }
  }

  Future<void> _handleDeleteAccount() async {
    final authService = AuthService();

    setState(() => _isLoading = true);

    try {
      await authService.deleteAccount();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LogInScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackBar(e.toString(), isError: true);
      }
    }
  }

  void _showDeleteAccountDialog() {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          l10n.deleteAccount,
          style: const TextStyle(color: Colors.red),
        ),
        content: Text(l10n.deleteAccountWarning),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _handleDeleteAccount();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(
              l10n.confirmDelete,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FF),
      body: Column(
        children: [
          _buildHeader(l10n),
          Expanded(
            child: _isLoading
                ? const AccountScreenSkeleton()
                : ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.symmetric(
                      horizontal: 24.w,
                      vertical: 24.h,
                    ),
                    children: [
                      _buildProfileForm(l10n),
                      SizedBox(height: 32.h),
                      _buildActionButtons(l10n),
                      SizedBox(height: 100.h),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      height: 180.h,
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.profile,
                style: TextStyle(
                  fontSize: 32.fSize,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              GestureDetector(
                onTap: _showDeleteAccountDialog,
                child: Container(
                  padding: EdgeInsets.all(8.adaptSize),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.delete_outline,
                    color: Colors.white,
                    size: 24.adaptSize,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileForm(AppLocalizations l10n) {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 50.adaptSize,
                  backgroundColor: AppColors.brandPurple.withOpacity(0.1),
                  backgroundImage: _localProfileImagePath != null
                      ? FileImage(File(_localProfileImagePath!))
                      : null,
                  child: _localProfileImagePath == null
                      ? Icon(
                          Icons.person,
                          size: 50.adaptSize,
                          color: AppColors.brandPurple,
                        )
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: _showImageSourceDialog,
                    child: Container(
                      padding: EdgeInsets.all(8.adaptSize),
                      decoration: BoxDecoration(
                        color: AppColors.brandPurple,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Icon(
                        Icons.camera_alt,
                        size: 16.adaptSize,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 20.h),

          // Name Field
          Text(
            l10n.name,
            style: TextStyle(
              fontSize: 14.fSize,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 5.h),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              hintText: l10n.name,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.adaptSize),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.adaptSize),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.adaptSize),
                borderSide: const BorderSide(color: AppColors.brandPurple),
              ),
              filled: true,
              fillColor: Colors.white,
              prefixIcon: const Icon(Icons.person_outline, color: Colors.grey),
            ),
          ),
          SizedBox(height: 15.h),

          // Email Field (Read-only)
          Text(
            l10n.email,
            style: TextStyle(
              fontSize: 14.fSize,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 5.h),
          TextField(
            controller: _emailController,
            readOnly: true,
            decoration: InputDecoration(
              hintText: l10n.email,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.adaptSize),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.grey.shade100, // indicate it's read only
              prefixIcon: const Icon(Icons.email_outlined, color: Colors.grey),
            ),
            style: const TextStyle(color: Colors.grey),
          ),
          SizedBox(height: 15.h),

          // Password Field
          Text(
            l10n.password,
            style: TextStyle(
              fontSize: 14.fSize,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 5.h),
          TextField(
            controller: _passwordController,
            obscureText: !_isPasswordVisible,
            decoration: InputDecoration(
              hintText: '••••••••',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.adaptSize),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.adaptSize),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.adaptSize),
                borderSide: const BorderSide(color: AppColors.brandPurple),
              ),
              filled: true,
              fillColor: Colors.white,
              prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey),
              suffixIcon: IconButton(
                icon: Icon(
                  _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                  color: Colors.grey,
                ),
                onPressed: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(AppLocalizations l10n) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _saveProfile,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandPurple,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 16.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.adaptSize),
              ),
              elevation: 4,
            ),
            child: Text(
              l10n.save, // 'Save' or similar text
              style: TextStyle(fontSize: 16.fSize, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        SizedBox(height: 16.h),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _showDeleteAccountDialog,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red, width: 1.5),
              padding: EdgeInsets.symmetric(vertical: 16.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.adaptSize),
              ),
            ),
            child: Text(
              l10n.deleteAccount,
              style: TextStyle(fontSize: 16.fSize, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}
