import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_screen.dart';
import 'home_screen.dart';

class RegisterScreen extends StatefulWidget {
  final String email;

  const RegisterScreen({
    super.key,
    required this.email,
  });

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  static const Color primary = Color(0xFF6C5CE7);
  static const Color secondary = Color(0xFF8E7BFF);
  static const Color background = Color(0xFFF5F6FF);

  final SupabaseClient client = Supabase.instance.client;
  final ImagePicker picker = ImagePicker();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController bioController = TextEditingController();

  File? selectedImage;

  bool loading = false;
  bool imageLoading = false;

  // ===============================================================
  // SHOW MESSAGE
  // ===============================================================
  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ===============================================================
  // LOGOUT
  // ===============================================================
  Future<void> logout() async {
    try {
      await client.auth.signOut();
    } catch (_) {}

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const AuthScreen(),
      ),
          (_) => false,
    );
  }

  // ===============================================================
  // PICK IMAGE
  // ===============================================================
  Future<void> pickImage() async {
    try {
      final XFile? file = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (file == null) return;

      if (!mounted) return;

      setState(() {
        selectedImage = File(file.path);
      });
    } catch (e) {
      showMessage('Failed to pick image.');
    }
  }

  // ===============================================================
  // UPLOAD AVATAR
  // ===============================================================
  Future<String?> uploadAvatar(String userId) async {
    if (selectedImage == null) return null;

    try {
      if (mounted) {
        setState(() {
          imageLoading = true;
        });
      }

      final bucket = client.storage.from('avatarz');

      final filePath =
          '$userId/avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';

      await bucket.upload(
        filePath,
        selectedImage!,
        fileOptions: const FileOptions(
          upsert: true,
          cacheControl: '3600',
        ),
      );

      final publicUrl = bucket.getPublicUrl(filePath);

      return '$publicUrl?t=${DateTime.now().millisecondsSinceEpoch}';
    } catch (e) {
      showMessage('Image upload failed.');
      return null;
    } finally {
      if (mounted) {
        setState(() {
          imageLoading = false;
        });
      }
    }
  }

  // ===============================================================
  // CREATE PROFILE
  // ===============================================================
  Future<void> createProfile() async {
    final user = client.auth.currentUser;

    if (user == null) {
      showMessage('Session expired. Please login again.');
      return;
    }

    final name = nameController.text.trim();
    final bio = bioController.text.trim();

    if (name.isEmpty) {
      showMessage('Please enter your name.');
      return;
    }

    if (loading) return;

    if (mounted) {
      setState(() {
        loading = true;
      });
    }

    try {
      final avatarUrl = await uploadAvatar(user.id);

      final now = DateTime.now().toUtc().toIso8601String();

      // Insert or update profile
      await client.from('profiles').upsert({
        'id': user.id,
        'email': widget.email.trim().toLowerCase(),
        'name': name,
        'bio': bio,
        'description': bio,
        'avatar_url': avatarUrl ?? '',
        'is_online': true,
        'last_seen': now,
        'created_at': now,
      });

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const HomeScreen(),
        ),
            (_) => false,
      );
    } catch (e) {
      showMessage('Failed to create profile: $e');
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  // ===============================================================
  // LOGO
  // ===============================================================
  Widget buildLogo() {
    return Column(
      children: [
        Hero(
          tag: 'nimo_logo',
          child: Image.asset(
            'assets/images/nimo_logo.png',
            width: 120,
            height: 120,
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Complete Your Profile',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Add your photo and personal details.',
          style: TextStyle(
            fontSize: 15,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  // ===============================================================
  // AVATAR
  // ===============================================================
  Widget buildAvatar() {
    return Stack(
      alignment: Alignment.center,
      children: [
        GestureDetector(
          onTap: imageLoading ? null : pickImage,
          child: Container(
            width: 132,
            height: 132,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [secondary, primary],
              ),
              boxShadow: [
                BoxShadow(
                  color: primary.withValues(alpha: 0.28),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: CircleAvatar(
              backgroundColor: Colors.white,
              backgroundImage:
              selectedImage != null ? FileImage(selectedImage!) : null,
              child: selectedImage == null
                  ? const Icon(
                Icons.person,
                size: 58,
                color: primary,
              )
                  : null,
            ),
          ),
        ),

        Positioned(
          bottom: 4,
          right: 4,
          child: Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: primary,
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white,
                width: 3,
              ),
            ),
            child: const Icon(
              Icons.camera_alt,
              size: 18,
              color: Colors.white,
            ),
          ),
        ),

        if (imageLoading)
          Container(
            width: 132,
            height: 132,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.45),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
              ),
            ),
          ),
      ],
    );
  }

  // ===============================================================
  // EMAIL CARD
  // ===============================================================
  Widget buildEmailCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 18,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(
            Icons.email_outlined,
            color: primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.email,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===============================================================
  // INPUT DECORATION
  // ===============================================================
  InputDecoration inputDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: primary),
      filled: true,
      fillColor: Colors.white,
      counterText: '',
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 18,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: const BorderSide(
          color: primary,
          width: 1.5,
        ),
      ),
    );
  }

  // ===============================================================
  // CREATE BUTTON
  // ===============================================================
  Widget buildCreateButton() {
    return Container(
      width: double.infinity,
      height: 58,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [secondary, primary],
        ),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.32),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: loading ? null : createProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          disabledBackgroundColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: loading
            ? const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: Colors.white,
          ),
        )
            : const Text(
          'Create Account',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  // ===============================================================
  // BUILD
  // ===============================================================
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          await logout();
        }
      },
      child: Scaffold(
        backgroundColor: background,
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          title: const Text(
            'Create Profile',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          leading: IconButton(
            onPressed: logout,
            icon: const Icon(
              Icons.arrow_back,
              color: Colors.black,
            ),
          ),
        ),
        body: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SafeArea(
            child: SingleChildScrollView(
              keyboardDismissBehavior:
              ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 60),
              child: Column(
                children: [
                  buildLogo(),
                  const SizedBox(height: 28),
                  buildAvatar(),
                  const SizedBox(height: 14),
                  Text(
                    'Tap to add profile photo',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 30),
                  buildEmailCard(),
                  const SizedBox(height: 20),

                  TextField(
                    controller: nameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: inputDecoration(
                      hint: 'Your name',
                      icon: Icons.person_outline,
                    ),
                  ),

                  const SizedBox(height: 20),

                  TextField(
                    controller: bioController,
                    maxLines: 4,
                    maxLength: 150,
                    decoration: inputDecoration(
                      hint: 'About you (optional)',
                      icon: Icons.info_outline,
                    ),
                  ),

                  const SizedBox(height: 8),

                  buildCreateButton(),

                  const SizedBox(height: 18),

                  Text(
                    'Your profile will be visible to your contacts on NIMO.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.5,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ===============================================================
  // DISPOSE
  // ===============================================================
  @override
  void dispose() {
    nameController.dispose();
    bioController.dispose();
    super.dispose();
  }
}