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
  // Colors
  static const Color primary = Color(0xFF6C5CE7);
  static const Color secondary = Color(0xFF8E7BFF);
  static const Color background = Color(0xFFF5F6FF);

  // Services
  final SupabaseClient client = Supabase.instance.client;
  final ImagePicker picker = ImagePicker();

  // Controllers
  final TextEditingController nameController = TextEditingController();
  final TextEditingController bioController = TextEditingController();

  // State
  File? selectedImage;
  bool loading = false;
  bool imageLoading = false;

  // --------------------------------------------------
  // Snackbar
  // --------------------------------------------------
  void showMessage(String text) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // --------------------------------------------------
  // Logout
  // --------------------------------------------------
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

  // --------------------------------------------------
  // Pick Image
  // --------------------------------------------------
  Future<void> pickImage() async {
    try {
      final XFile? picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (picked == null) return;

      setState(() {
        selectedImage = File(picked.path);
      });
    } catch (e) {
      debugPrint('IMAGE PICK ERROR: $e');
      showMessage('Failed to pick image.');
    }
  }

  // --------------------------------------------------
  // Upload Avatar
  // --------------------------------------------------
  Future<String?> uploadAvatar(String userId) async {
    if (selectedImage == null) return null;

    try {
      setState(() => imageLoading = true);

      final storage = client.storage.from('avatarz');

      final filePath =
          '$userId/avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';

      await storage.upload(
        filePath,
        selectedImage!,
        fileOptions: const FileOptions(
          upsert: true,
          cacheControl: '3600',
        ),
      );

      final publicUrl = storage.getPublicUrl(filePath);

      return '$publicUrl?t=${DateTime.now().millisecondsSinceEpoch}';
    } catch (e) {
      debugPrint('UPLOAD ERROR: $e');
      showMessage('Image upload failed.');
      return null;
    } finally {
      if (mounted) {
        setState(() => imageLoading = false);
      }
    }
  }

  // --------------------------------------------------
  // Create Profile
  // --------------------------------------------------
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

    setState(() => loading = true);

    try {
      final avatarUrl = await uploadAvatar(user.id);

      await client.from('profiles').upsert({
        'id': user.id,
        'email': widget.email.trim().toLowerCase(),
        'name': name,
        'description': bio,
        'bio': bio,
        'avatar_url': avatarUrl ?? '',
        'is_online': true,
        'last_seen': DateTime.now().toUtc().toIso8601String(),
        'created_at': DateTime.now().toUtc().toIso8601String(),
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
      debugPrint('REGISTER ERROR: $e');
      showMessage('Failed to create profile.');
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  // --------------------------------------------------
  // Logo
  // --------------------------------------------------
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
            color: Color(0xFF111111),
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

  // --------------------------------------------------
  // Avatar
  // --------------------------------------------------
  Widget buildAvatar() {
    return Stack(
      alignment: Alignment.center,
      children: [
        GestureDetector(
          onTap: imageLoading ? null : pickImage,
          child: Container(
            width: 132,
            height: 132,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [secondary, primary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: primary.withAlpha(70),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            padding: const EdgeInsets.all(4),
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
              color: Colors.black.withAlpha(120),
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

  // --------------------------------------------------
  // Email Card
  // --------------------------------------------------
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
            color: Colors.black.withAlpha(8),
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

  // --------------------------------------------------
  // Input Decoration
  // --------------------------------------------------
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

  // --------------------------------------------------
  // Create Button
  // --------------------------------------------------
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
            color: primary.withAlpha(80),
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

  // --------------------------------------------------
  // Build
  // --------------------------------------------------
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
            child: AnimatedPadding(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: SingleChildScrollView(
                reverse: true,
                keyboardDismissBehavior:
                ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                child: Column(
                  children: [
                    const SizedBox(height: 8),
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

                    // Name
                    TextField(
                      controller: nameController,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      decoration: inputDecoration(
                        hint: 'Your name',
                        icon: Icons.person_outline,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Bio
                    TextField(
                      controller: bioController,
                      maxLines: 4,
                      maxLength: 150,
                      textInputAction: TextInputAction.done,
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

                    // Extra bottom spacing for keyboard safety
                    const SizedBox(height: 60),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------
  // Dispose
  // --------------------------------------------------
  @override
  void dispose() {
    nameController.dispose();
    bioController.dispose();
    super.dispose();
  }
}