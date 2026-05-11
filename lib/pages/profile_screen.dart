import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import 'notifications_screen.dart';
import '../localization/app_localizations.dart';
import '../services/notification_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;enum _PhotoTarget { profile, cover }

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool isMale = true;
  bool get isDark => context.watch<ThemeProvider>().isDarkMode;

  final _formKey = GlobalKey<FormState>();

  final firstNameC = TextEditingController();
  final lastNameC = TextEditingController();
  final emailC = TextEditingController();
  final dobC = TextEditingController();

  DateTime? selectedDob;

  File? profileFile;
  File? coverFile;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();

      final parts = (auth.fullName ?? "").trim().split(RegExp(r"\s+"));
      firstNameC.text =
      parts.isNotEmpty && parts.first.isNotEmpty ? parts.first : "";
      lastNameC.text = parts.length > 1 ? parts.sublist(1).join(" ") : "";

      emailC.text = auth.email ?? "";

      final g = (auth.gender ?? "male").toLowerCase();
      isMale = g == "male";

      final rawDob = auth.dob;
      if (rawDob != null && rawDob.isNotEmpty) {
        final parsed = DateTime.tryParse(rawDob);
        if (parsed != null) {
          selectedDob = parsed;
          dobC.text = _formatDob(parsed);
        } else {
          selectedDob = null;
          dobC.text = "";
        }
      } else {
        selectedDob = null;
        dobC.text = "";
      }

      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    firstNameC.dispose();
    lastNameC.dispose();
    emailC.dispose();
    dobC.dispose();
    super.dispose();
  }

  String _formatDob(DateTime d) =>
      "${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}";

  DateTime get _maxDob => DateTime(
    DateTime.now().year - 15,
    DateTime.now().month,
    DateTime.now().day,
  );

  Future<void> _pickDob() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDob ?? _maxDob,
      firstDate: DateTime(1900, 1, 1),
      lastDate: _maxDob,
    );
    if (picked == null) return;

    setState(() {
      selectedDob = picked;
      dobC.text = _formatDob(picked);
    });
  }

  Future<bool> _requestPhotoPermission(ImageSource source) async {
    final permission =
    source == ImageSource.camera ? Permission.camera : Permission.photos;
    var status = await permission.status;

    if (status.isGranted) return true;
    if (status.isPermanentlyDenied) {
      if (!mounted) return false;
      final shouldOpen = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(context.tr('permission_required')),
          content: Text(
            "${context.tr('please_allow')} "
                "${source == ImageSource.camera ? context.tr('camera') : context.tr('photo_library')} "
                "${context.tr('access_in_settings_to')} "
                "${source == ImageSource.camera ? context.tr('take') : context.tr('select')} "
                "${context.tr('photos')}.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(context.tr('cancel')),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(context.tr('open_settings')),
            ),
          ],
        ),
      );
      if (shouldOpen == true) await openAppSettings();
      return false;
    }

    var result = await permission.request();
    if (source == ImageSource.gallery &&
        !result.isGranted &&
        Platform.isAndroid) {
      result = await Permission.storage.request();
    }

    if (!result.isGranted && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "${source == ImageSource.camera ? context.tr('camera') : context.tr('photo_library')} "
                "${context.tr('access_required_to')} "
                "${source == ImageSource.camera ? context.tr('take') : context.tr('select')} "
                "${context.tr('photos')}.",
          ),
        ),
      );
    }
    return result.isGranted;
  }

  Future<void> _pickImage(_PhotoTarget target, ImageSource source) async {
    final hasPermission = await _requestPhotoPermission(source);
    if (!hasPermission || !mounted) return;

    final picked = await ImagePicker().pickImage(
      source: source,
      imageQuality: 85,
    );
    if (picked == null) return;

    setState(() {
      if (target == _PhotoTarget.profile) {
        profileFile = File(picked.path);
      } else {
        coverFile = File(picked.path);
      }
    });

    if (!mounted) return;
    Navigator.pop(context);
  }

  void _openChangePhotoDialog(_PhotoTarget target) {
    final auth = context.read<AuthProvider>();
    final canDelete =
    target == _PhotoTarget.profile ? !auth.isDefaultPhoto : !auth.isDefaultCover;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        final screenWidth = MediaQuery.of(context).size.width;

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            width: screenWidth > 600 ? 420 : screenWidth * 0.9,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xff1A2B49) : const Color(0xffF5EFE4),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 15,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Text(
                      context.tr('change_picture'),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: isDark ? Colors.white : const Color(0xff1A2B49),
                      ),
                    ),
                    PositionedDirectional(
                      end: 0,
                      top: 0,
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Icon(
                          Icons.close,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () => _pickImage(target, ImageSource.gallery),
                  child: _dialogButton(
                    icon: Icons.photo_library_outlined,
                    text: context.tr('upload_from_library'),
                  ),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () => _pickImage(target, ImageSource.camera),
                  child: _dialogButton(
                    icon: Icons.camera_alt_outlined,
                    text: context.tr('take_photo_with_camera'),
                  ),
                ),
                if (canDelete) ...[
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () async {
                      final auth = context.read<AuthProvider>();

                      if (target == _PhotoTarget.profile) {
                        await auth.deleteProfilePhoto();
                        setState(() => profileFile = null);
                      } else {
                        await auth.deleteCoverPhoto();
                        setState(() => coverFile = null);
                      }

                      if (!mounted) return;
                      Navigator.pop(context);
                    },
                    child: _dialogButton(
                      icon: Icons.delete_outline,
                      text: context.tr('delete_photo'),
                      color: Colors.red,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _dialogButton({
    required IconData icon,
    required String text,
    Color? color,
    Color? iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFFF5A623) : Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: iconColor ??
                color ??
                (isDark ? const Color(0xff1A2B49) : const Color(0xff1A2B49)),
          ),
          const SizedBox(width: 10),
          Text(
            text,
            style: TextStyle(
              color: color ??
                  (isDark ? const Color(0xff1A2B49) : const Color(0xff1A2B49)),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final themeProvider = context.watch<ThemeProvider>();

    Widget coverWidget() {
      if (coverFile != null) {
        return Image.file(
          coverFile!,
          height: 150,
          width: double.infinity,
          fit: BoxFit.cover,
        );
      }
      final url = auth.coverUrl ?? "";
      if (url.isNotEmpty) {
        return Image.network(
          url,
          height: 150,
          width: double.infinity,
          fit: BoxFit.cover,
        );
      }
      return Image.asset(
        "images/defaultCover.png",
        height: 150,
        width: double.infinity,
        fit: BoxFit.cover,
      );
    }

    ImageProvider profileProvider() {
      if (profileFile != null) return FileImage(profileFile!);
      final url = auth.photoUrl ?? "";
      if (url.isNotEmpty) return NetworkImage(url);
      return const AssetImage("images/defaultUserProfile.png");
    }

    return Scaffold(
      backgroundColor:
      isDark ? themeProvider.backgroundColor : const Color(0xffF5EFE4),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: isDark ? Colors.white : Colors.black),
        centerTitle: true,
        title: Text(
          context.tr('profile'),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xff1A2B49),
            fontSize: 20,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 16),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const NotificationsScreen(),
                  ),
                );
              },
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    Icons.notifications,
                    size: 28,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                  PositionedDirectional(
                    end: -1,
                    top: -2,
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection("notifications")
                          .where("userId", isEqualTo: firebase_auth.FirebaseAuth.instance.currentUser?.uid)                          .where("isRead", isEqualTo: false)
                          .snapshots(),
                      builder: (context, snapshot) {

                        if (!snapshot.hasData ||
                            snapshot.data!.docs.isEmpty) {
                          return const SizedBox();
                        }

                        final count = snapshot.data!.docs.length;

                        return Container(
                          padding: const EdgeInsets.all(3),
                          constraints: const BoxConstraints(
                            minWidth: 18,
                            minHeight: 18,
                          ),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            count.toString(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsetsDirectional.fromSTEB(20, 10, 20, 24),
          child: Column(
            children: [
              SizedBox(
                height: 210,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: coverWidget(),
                    ),
                    PositionedDirectional(
                      end: 12,
                      top: 12,
                      child: GestureDetector(
                        onTap: () => _openChangePhotoDialog(_PhotoTarget.cover),
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.edit,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                    PositionedDirectional(
                      start: 0,
                      end: 0,
                      top: 95,
                      child: Center(
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 42,
                              backgroundColor: Colors.white,
                              child: CircleAvatar(
                                radius: 38,
                                backgroundImage: profileProvider(),
                              ),
                            ),
                            PositionedDirectional(
                              end: 0,
                              bottom: 0,
                              child: GestureDetector(
                                onTap: () =>
                                    _openChangePhotoDialog(_PhotoTarget.profile),
                                child: Container(
                                  width: 30,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.edit,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              _inputField(
                context.tr('first_name'),
                firstNameC,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return context.tr('error_first_name_required');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              _inputField(
                context.tr('last_name'),
                lastNameC,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return context.tr('error_last_name_required');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              _inputField(context.tr('email_label'), emailC, enabled: false),
              const SizedBox(height: 8),
              _dateField(),
              const SizedBox(height: 8),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  context.tr('gender'),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: isDark
                        ? const Color(0xFF89B0D8)
                        : const Color(0xff1A2B49),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _genderButton(
                    context.tr('male'),
                    isMale,
                        () => setState(() => isMale = true),
                  ),
                  const SizedBox(width: 12),
                  _genderButton(
                    context.tr('female'),
                    !isMale,
                        () => setState(() => isMale = false),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark
                        ? const Color(0xFFF5A623)
                        : const Color(0xff1A2B49),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: auth.isLoading
                      ? null
                      : () async {
                    if (!_formKey.currentState!.validate()) return;

                    final ok = await context.read<AuthProvider>().updateProfile(
                      firstName: firstNameC.text.trim(),
                      lastName: lastNameC.text.trim(),
                      email: emailC.text.trim(),
                      gender: isMale ? "male" : "female",
                      dob: selectedDob?.toIso8601String(),
                      profileImageFile: profileFile,
                      coverImageFile: coverFile,
                      location: '',
                    );

                    if (!mounted) return;

                    if (ok) {

                      await NotificationService.addNotification(
                        title: "Profile Updated",
                        message: "Your profile information has been updated successfully.",
                        type: "profile_update",
                      );

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(context.tr('profile_updated_success')),
                        ),
                      );

                      Navigator.pushNamed(context, '/setting');

                    } else {

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            auth.error != null
                                ? context.tr(auth.error!)
                                : context.tr('update_failed'),
                          ),
                        ),
                      );

                    }
                  },
                  child: auth.isLoading
                      ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : Text(
                    context.tr('save_changes'),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? const Color(0xFF1A2B49)
                          : Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr('date_of_birth'),
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isDark ? const Color(0xFF89B0D8) : const Color(0xff1A2B49),
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: dobC,
          style: const TextStyle(color: Color(0xff1A2B49)),
          readOnly: true,
          onTap: _pickDob,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            suffixIcon: IconButton(
              icon: const Icon(
                Icons.calendar_today_outlined,
                size: 20,
                color: Color(0xff1A2B49),
              ),
              onPressed: _pickDob,
            ),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 14,
              horizontal: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xff1A2B49), width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xff1A2B49), width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xff1A2B49), width: 1),
            ),
          ),
        ),
      ],
    );
  }

  Widget _inputField(
      String label,
      TextEditingController controller, {
        IconData? suffixIcon,
        bool enabled = true,
        String? Function(String?)? validator,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isDark ? const Color(0xFF89B0D8) : const Color(0xff1A2B49),
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          enabled: enabled,
          validator: validator,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          style: const TextStyle(color: Color(0xff1A2B49)),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            suffixIcon: suffixIcon != null ? Icon(suffixIcon, size: 20) : null,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 14,
              horizontal: 12,
            ),
            errorStyle: const TextStyle(
              color: Colors.red,
              fontSize: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xff1A2B49), width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xff1A2B49), width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xff1A2B49), width: 1),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.red, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.red, width: 1),
            ),
          ),
        ),
      ],
    );
  }

  Widget _genderButton(String text, bool active, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: active ? const Color(0xffF5A623) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xff1A2B49)),
          ),
          alignment: Alignment.center,
          child: Text(
            text,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xff1A2B49),
            ),
          ),
        ),
      ),
    );
  }
}
