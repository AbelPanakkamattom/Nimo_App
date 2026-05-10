import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/profile_service.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> profile;

  const EditProfileScreen({
    super.key,
    required this.profile,
  });

  @override
  State<EditProfileScreen> createState() =>
      _EditProfileScreenState();
}

class _EditProfileScreenState
    extends State<EditProfileScreen> {
  static const Color primary =
  Color(0xFF6C5CE7);
  static const Color secondary =
  Color(0xFF8E7BFF);
  static const Color background =
  Color(0xFFF5F6FF);

  final ImagePicker _picker =
  ImagePicker();

  late final TextEditingController
  _nameController;
  late final TextEditingController
  _bioController;

  File? _selectedImage;

  bool _saving = false;
  bool _uploading = false;

  // =========================================================
  // INIT
  // =========================================================

  @override
  void initState() {
    super.initState();

    _nameController =
        TextEditingController(
          text: widget.profile['name']
              ?.toString() ??
              widget.profile['username']
                  ?.toString() ??
              '',
        );

    _bioController =
        TextEditingController(
          text: widget.profile['bio']
              ?.toString() ??
              widget.profile['description']
                  ?.toString() ??
              '',
        );
  }

  // =========================================================
  // HELPERS
  // =========================================================

  bool get _isBusy =>
      _saving || _uploading;

  void _showMessage(
      String message, {
        Color? color,
      }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
        behavior:
        SnackBarBehavior.floating,
        backgroundColor:
        color ?? primary,
      ),
    );
  }

  // =========================================================
  // PICK IMAGE
  // =========================================================

  Future<void> _pickImage() async {
    try {
      final file =
      await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (file == null) return;

      if (!mounted) return;

      setState(() {
        _selectedImage =
            File(file.path);
      });
    } catch (e) {
      debugPrint(
        'PICK IMAGE ERROR: $e',
      );
      _showMessage(
        'Failed to pick image.',
        color: Colors.redAccent,
      );
    }
  }

  // =========================================================
  // SAVE PROFILE
  // =========================================================

  Future<void> _saveProfile() async {
    if (_saving) return;

    final name = _nameController.text
        .trim();
    final bio = _bioController.text
        .trim();

    if (name.isEmpty) {
      _showMessage(
        'Please enter your name.',
        color: Colors.orange,
      );
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      await ProfileService
          .createProfileIfNotExists();

      String? avatarUrl;

      if (_selectedImage != null) {
        setState(() {
          _uploading = true;
        });

        avatarUrl =
        await ProfileService
            .uploadAvatar(
          _selectedImage!,
        );

        if (mounted) {
          setState(() {
            _uploading = false;
          });
        }
      }

      final success =
      await ProfileService
          .updateProfile(
        name: name,
        bio: bio,
        avatarUrl: avatarUrl,
      );

      if (!success) {
        throw Exception(
          'Profile update failed.',
        );
      }

      if (!mounted) return;

      _showMessage(
        'Profile updated successfully.',
      );

      Navigator.pop(context, true);
    } catch (e) {
      debugPrint(
        'SAVE PROFILE ERROR: $e',
      );

      if (mounted) {
        setState(() {
          _uploading = false;
        });
      }

      _showMessage(
        'Failed to update profile.',
        color: Colors.redAccent,
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  // =========================================================
  // AVATAR
  // =========================================================

  Widget _buildAvatar() {
    final currentAvatar =
        widget.profile['avatar_url']
            ?.toString() ??
            '';

    ImageProvider? provider;

    if (_selectedImage != null) {
      provider = FileImage(
        _selectedImage!,
      );
    } else if (currentAvatar
        .isNotEmpty) {
      provider = NetworkImage(
        currentAvatar,
      );
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        GestureDetector(
          onTap:
          _isBusy
              ? null
              : _pickImage,
          child: Container(
            width: 136,
            height: 136,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient:
              const LinearGradient(
                colors: [
                  secondary,
                  primary,
                ],
                begin:
                Alignment.topLeft,
                end: Alignment
                    .bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color:
                  primary.withAlpha(
                    80,
                  ),
                  blurRadius: 24,
                  offset:
                  const Offset(
                    0,
                    10,
                  ),
                ),
              ],
            ),
            padding:
            const EdgeInsets.all(
              4,
            ),
            child: CircleAvatar(
              backgroundColor:
              Colors.white,
              backgroundImage:
              provider,
              child:
              provider == null
                  ? const Icon(
                Icons.person,
                size: 58,
                color:
                primary,
              )
                  : null,
            ),
          ),
        ),

        Positioned(
          right: 4,
          bottom: 4,
          child: GestureDetector(
            onTap:
            _isBusy
                ? null
                : _pickImage,
            child: Container(
              padding:
              const EdgeInsets
                  .all(9),
              decoration:
              BoxDecoration(
                color: primary,
                shape:
                BoxShape.circle,
                border:
                Border.all(
                  color:
                  Colors.white,
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: primary
                        .withAlpha(
                      70,
                    ),
                    blurRadius: 12,
                    offset:
                    const Offset(
                      0,
                      4,
                    ),
                  ),
                ],
              ),
              child: const Icon(
                Icons.camera_alt,
                size: 18,
                color:
                Colors.white,
              ),
            ),
          ),
        ),

        if (_uploading)
          Container(
            width: 136,
            height: 136,
            decoration:
            BoxDecoration(
              color: Colors.black
                  .withAlpha(120),
              shape:
              BoxShape.circle,
            ),
            child: const Center(
              child:
              CircularProgressIndicator(
                color:
                Colors.white,
              ),
            ),
          ),
      ],
    );
  }

  // =========================================================
  // TEXT FIELD
  // =========================================================

  Widget _buildTextField({
    required TextEditingController
    controller,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    int? maxLength,
    TextCapitalization
    capitalization =
        TextCapitalization
            .sentences,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(
          22,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withAlpha(8),
            blurRadius: 12,
            offset:
            const Offset(
              0,
              6,
            ),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        enabled: !_isBusy,
        maxLines: maxLines,
        maxLength: maxLength,
        textCapitalization:
        capitalization,
        textInputAction:
        maxLines > 1
            ? TextInputAction
            .newline
            : TextInputAction
            .next,
        decoration:
        InputDecoration(
          hintText: hint,
          counterText: '',
          prefixIcon: Padding(
            padding:
            EdgeInsets.only(
              bottom:
              maxLines > 1
                  ? 72
                  : 0,
            ),
            child: Icon(
              icon,
              color: primary,
            ),
          ),
          filled: true,
          fillColor:
          Colors.white,
          border:
          OutlineInputBorder(
            borderRadius:
            BorderRadius.circular(
              22,
            ),
            borderSide:
            BorderSide.none,
          ),
          enabledBorder:
          OutlineInputBorder(
            borderRadius:
            BorderRadius.circular(
              22,
            ),
            borderSide:
            BorderSide.none,
          ),
          focusedBorder:
          OutlineInputBorder(
            borderRadius:
            BorderRadius.circular(
              22,
            ),
            borderSide:
            const BorderSide(
              color: primary,
              width: 1.5,
            ),
          ),
          contentPadding:
          const EdgeInsets
              .symmetric(
            horizontal: 18,
            vertical: 18,
          ),
        ),
      ),
    );
  }

  // =========================================================
  // SAVE BUTTON
  // =========================================================

  Widget _buildSaveButton() {
    return Container(
      width: double.infinity,
      height: 58,
      decoration: BoxDecoration(
        borderRadius:
        BorderRadius.circular(
          18,
        ),
        gradient:
        const LinearGradient(
          colors: [
            secondary,
            primary,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color:
            primary.withAlpha(
              80,
            ),
            blurRadius: 20,
            offset:
            const Offset(
              0,
              10,
            ),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed:
        _isBusy
            ? null
            : _saveProfile,
        style:
        ElevatedButton.styleFrom(
          backgroundColor:
          Colors.transparent,
          shadowColor:
          Colors.transparent,
          disabledBackgroundColor:
          Colors.transparent,
          shape:
          RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(
              18,
            ),
          ),
        ),
        child:
        _isBusy
            ? const SizedBox(
          width: 24,
          height: 24,
          child:
          CircularProgressIndicator(
            strokeWidth:
            2.5,
            color:
            Colors.white,
          ),
        )
            : const Text(
          'Save Changes',
          style: TextStyle(
            fontSize: 17,
            fontWeight:
            FontWeight
                .w700,
            color:
            Colors.white,
          ),
        ),
      ),
    );
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(
      BuildContext context,
      ) {
    return Scaffold(
      backgroundColor:
      background,
      resizeToAvoidBottomInset:
      true,
      appBar: AppBar(
        backgroundColor:
        Colors.transparent,
        elevation: 0,
        surfaceTintColor:
        Colors.transparent,
        foregroundColor:
        Colors.black,
        centerTitle: false,
        titleSpacing: 0,
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            fontSize: 22,
            fontWeight:
            FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
      body: GestureDetector(
        onTap:
            () => FocusScope.of(
          context,
        ).unfocus(),
        child: SafeArea(
          child: AnimatedPadding(
            duration:
            const Duration(
              milliseconds: 250,
            ),
            curve: Curves.easeOut,
            padding:
            EdgeInsets.only(
              bottom:
              MediaQuery.of(
                context,
              ).viewInsets.bottom,
            ),
            child:
            SingleChildScrollView(
              reverse: true,
              keyboardDismissBehavior:
              ScrollViewKeyboardDismissBehavior
                  .onDrag,
              padding:
              const EdgeInsets.all(
                20,
              ),
              child: Column(
                children: [
                  const SizedBox(
                    height: 10,
                  ),

                  _buildAvatar(),

                  const SizedBox(
                    height: 14,
                  ),

                  const Text(
                    'Tap photo to change',
                    style: TextStyle(
                      color:
                      Colors.grey,
                      fontSize: 13,
                    ),
                  ),

                  const SizedBox(
                    height: 32,
                  ),

                  _buildTextField(
                    controller:
                    _nameController,
                    hint:
                    'Your name',
                    icon: Icons
                        .person_outline,
                    capitalization:
                    TextCapitalization
                        .words,
                  ),

                  const SizedBox(
                    height: 20,
                  ),

                  _buildTextField(
                    controller:
                    _bioController,
                    hint:
                    'About you',
                    icon: Icons
                        .info_outline,
                    maxLines: 4,
                    maxLength: 150,
                  ),

                  const SizedBox(
                    height: 36,
                  ),

                  _buildSaveButton(),

                  const SizedBox(
                    height: 20,
                  ),

                  Text(
                    'Your profile information will be visible to your contacts on NIMO.',
                    textAlign:
                    TextAlign
                        .center,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.5,
                      color: Colors
                          .grey
                          .shade600,
                    ),
                  ),

                  // Extra space to prevent keyboard overflow
                  const SizedBox(
                    height: 120,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // =========================================================
  // DISPOSE
  // =========================================================

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }
}