import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart' as app_auth;
import '../providers/theme_provider.dart';
import '../language_provider.dart';
import '../localization/app_localizations.dart';
import 'ChangePass.dart';
import '../widgets/admin_footer.dart';

enum _PhotoTarget { profile, cover }

class AdminProfilePage extends StatefulWidget {
  const AdminProfilePage({super.key});

  @override
  State<AdminProfilePage> createState() => _AdminProfilePageState();
}

class _AdminProfilePageState extends State<AdminProfilePage> {
  final _formKey = GlobalKey<FormState>();

  final firstName = TextEditingController();
  final lastName = TextEditingController();
  final email = TextEditingController();
  final dobC = TextEditingController();

  DateTime? selectedDob;
  bool _init = false;

  File? profileFile;
  File? coverFile;

  String _selectedLanguage = 'en';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_init) return;

    final auth = context.read<app_auth.AuthProvider>();
    final user = FirebaseAuth.instance.currentUser;
    final languageProvider = context.read<LanguageProvider>();

    final parts = (auth.fullName ?? "").trim().split(RegExp(r"\s+"));
    firstName.text =
    parts.isNotEmpty && parts.first.isNotEmpty ? parts.first : "";
    lastName.text = parts.length > 1 ? parts.sublist(1).join(" ") : "";

    email.text = (auth.email ?? user?.email ?? "").trim();

    final rawDob = auth.dob;
    if (rawDob != null && rawDob.isNotEmpty) {
      final parsed = DateTime.tryParse(rawDob);
      if (parsed != null) {
        selectedDob = parsed;
        dobC.text = _formatDob(parsed);
      }
    }

    _selectedLanguage = languageProvider.locale.languageCode;
    _init = true;
  }

  @override
  void dispose() {
    firstName.dispose();
    lastName.dispose();
    email.dispose();
    dobC.dispose();
    super.dispose();
  }

  String _formatDob(DateTime d) =>
      "${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}";

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

      if (shouldOpen == true) {
        await openAppSettings();
      }
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
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final hasPermission = await _requestPhotoPermission(source);
    if (!hasPermission || !mounted) return;

    try {
      final picked =
      await ImagePicker().pickImage(source: source, imageQuality: 85);
      if (picked == null) return;

      setState(() {
        if (target == _PhotoTarget.profile) {
          profileFile = File(picked.path);
        } else {
          coverFile = File(picked.path);
        }
      });

      if (!mounted) return;
      navigator.pop();
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(context.tr('image_picker_failed'))),
      );
    }
  }

  void _openChangePhotoDialog(_PhotoTarget target) {
    final auth = context.read<app_auth.AuthProvider>();
    final canDelete = target == _PhotoTarget.profile
        ? !auth.isDefaultPhoto
        : !auth.isDefaultCover;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        final isDark = dialogContext.watch<ThemeProvider>().isDarkMode;

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            width: 320,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF3F4E67)
                  : Theme.of(dialogContext).cardColor,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 12,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Center(
                      child: Text(
                        dialogContext.tr('change_picture'),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: isDark
                              ? const Color(0xFFF5A623)
                              : Theme.of(dialogContext).colorScheme.onSurface,
                        ),
                      ),
                    ),
                    PositionedDirectional(
                      end: 0,
                      top: 0,
                      child: GestureDetector(
                        onTap: () => Navigator.pop(dialogContext),
                        child: const Icon(Icons.close),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () => _pickImage(target, ImageSource.gallery),
                  child: _dialogButton(
                    icon: Icons.photo_library_outlined,
                    text: dialogContext.tr('upload_from_library'),
                  ),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () => _pickImage(target, ImageSource.camera),
                  child: _dialogButton(
                    icon: Icons.camera_alt_outlined,
                    text: dialogContext.tr('take_photo_with_camera'),
                  ),
                ),
                if (canDelete) ...[
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () async {
                      final authProvider = context.read<app_auth.AuthProvider>();

                      if (target == _PhotoTarget.profile) {
                        await authProvider.deleteProfilePhoto();
                        if (mounted) {
                          setState(() => profileFile = null);
                        }
                      } else {
                        await authProvider.deleteCoverPhoto();
                        if (mounted) {
                          setState(() => coverFile = null);
                        }
                      }

                      if (!mounted) return;
                      Navigator.pop(dialogContext);
                    },
                    child: _dialogButton(
                      icon: Icons.delete_outline,
                      iconColor: Colors.white,
                      text: dialogContext.tr('delete_photo'),
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
    final isDark = context.watch<ThemeProvider>().isDarkMode;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFFF5A623) : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: iconColor ?? color ?? Theme.of(context).colorScheme.onSurface,
          ),
          const SizedBox(width: 10),
          Text(
            text,
            style: TextStyle(
              color: color ?? const Color(0xFF1A2B49),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  ImageProvider _profileProvider(app_auth.AuthProvider auth) {
    if (profileFile != null) return FileImage(profileFile!);

    final url = auth.photoUrl ?? "";
    if (url.isNotEmpty) return NetworkImage(url);

    return const AssetImage("images/defaultUserProfile.png");
  }

  Widget _coverWidget(app_auth.AuthProvider auth) {
    if (coverFile != null) {
      return Image.file(
        coverFile!,
        height: 140,
        width: double.infinity,
        fit: BoxFit.cover,
      );
    }

    final url = auth.coverUrl ?? "";
    if (url.isNotEmpty) {
      return Image.network(
        url,
        height: 140,
        width: double.infinity,
        fit: BoxFit.cover,
      );
    }

    return Image.asset(
      "images/defaultCover.png",
      height: 140,
      width: double.infinity,
      fit: BoxFit.cover,
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<app_auth.AuthProvider>();
    final themeProvider = context.watch<ThemeProvider>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<app_auth.AuthProvider>().loadUserProfile();
    });

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                Center(
                  child: Text(
                    context.tr('profile'),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 210,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      PositionedDirectional(
                        top: 0,
                        start: 16,
                        end: 16,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: SizedBox(
                            height: 140,
                            child: _coverWidget(auth),
                          ),
                        ),
                      ),
                      PositionedDirectional(
                        top: 10,
                        end: 22,
                        child: GestureDetector(
                          onTap: () => _openChangePhotoDialog(_PhotoTarget.cover),
                          child: Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(
                              Icons.edit,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      PositionedDirectional(
                        top: 110,
                        start: 0,
                        end: 0,
                        child: Center(
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              CircleAvatar(
                                radius: 32,
                                backgroundColor: Theme.of(context).cardColor,
                                child: CircleAvatar(
                                  radius: 28,
                                  backgroundImage: _profileProvider(auth),
                                ),
                              ),
                              PositionedDirectional(
                                end: -2,
                                bottom: -2,
                                child: GestureDetector(
                                  onTap: () =>
                                      _openChangePhotoDialog(_PhotoTarget.profile),
                                  child: Container(
                                    width: 24,
                                    height: 24,
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
                                      size: 12,
                                      color: Colors.white,
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
                const SizedBox(height: 16),
                _field(
                  context.tr('first_name'),
                  firstName,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return context.tr('error_first_name_required');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                _field(
                  context.tr('last_name'),
                  lastName,
                  hint: context.tr('last_name'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return context.tr('error_last_name_required');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                _field(
                  context.tr('email_label'),
                  email,
                  enabled: false,
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsetsDirectional.only(start: 16, bottom: 4),
                  child: Text(
                    context.tr('date_of_birth'),
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    border: Border.all(color: Theme.of(context).dividerColor),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        dobC.text.isEmpty ? context.tr('date_of_birth') : dobC.text,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      Icon(
                        Icons.calendar_month,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 25),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Theme.of(context).dividerColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('preferences'),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _settingRow(
                        icon: Icons.nightlight_round,
                        title: context.tr('dark_mode'),
                        trailing: Switch(
                          value: themeProvider.isDarkMode,
                          activeThumbColor: Colors.green,
                          activeTrackColor: Colors.green.withValues(alpha: 0.4),
                          onChanged: (v) {
                            context.read<ThemeProvider>().setDarkMode(v);
                          },
                        ),
                      ),
                      _settingRow(
                        icon: Icons.language,
                        title: context.tr('language'),
                        trailing: DropdownButton<String>(
                          value: _selectedLanguage,
                          underline: const SizedBox(),
                          items: const [
                            DropdownMenuItem(
                              value: 'en',
                              child: Text('English'),
                            ),
                            DropdownMenuItem(
                              value: 'ar',
                              child: Text('العربية'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() {
                              _selectedLanguage = value;
                            });
                          },
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ChangePass(),
                            ),
                          );
                        },
                        child: _settingRow(
                          icon: Icons.lock_outline,
                          title: context.tr('change_password'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 25),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        child: ElevatedButton(
                          onPressed: auth.isLoading
                              ? null
                              : () async {
                            if (!_formKey.currentState!.validate()) return;

                            final authProvider =
                            context.read<app_auth.AuthProvider>();
                            final languageProvider =
                            context.read<LanguageProvider>();

                            final oldLanguage =
                                languageProvider.locale.languageCode;

                            final ok = await authProvider.updateProfile(
                              firstName: firstName.text.trim(),
                              lastName: lastName.text.trim(),
                              email: email.text.trim(),
                              location: auth.location ?? "",
                              gender: auth.gender ?? "male",
                              dob: selectedDob?.toIso8601String(),
                              profileImageFile: profileFile,
                              coverImageFile: coverFile,
                            );

                            if (!mounted) return;

                            if (_selectedLanguage != oldLanguage) {
                              await languageProvider.changeLanguage(
                                _selectedLanguage,
                              );
                            }

                            if (!mounted) return;

                            String message;
                            if (ok) {
                              message = _selectedLanguage == 'ar'
                                  ? 'تم تحديث الملف بنجاح'
                                  : 'Profile updated successfully';
                            } else {
                              message = _selectedLanguage == 'ar'
                                  ? 'فشل التحديث'
                                  : 'Update failed';
                            }

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(message)),
                            );

                            if (ok) {
                              setState(() {
                                profileFile = null;
                                coverFile = null;
                              });
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                            Theme.of(context).colorScheme.primary,
                          ),
                          child: auth.isLoading
                              ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                              : Text(context.tr('save_changes')),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        margin: const EdgeInsetsDirectional.only(end: 16),
                        child: ElevatedButton(
                          onPressed: () => _showLogoutDialog(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          child: Text(context.tr('logout')),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: const AdminFooter(currentIndex: 4),
    );
  }

  Widget _field(
      String label,
      TextEditingController c, {
        String? hint,
        bool enabled = true,
        String? Function(String?)? validator,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          TextFormField(
            controller: c,
            enabled: enabled,
            validator: validator,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            decoration: InputDecoration(
              hintText: hint,
              filled: true,
              fillColor: Theme.of(context).cardColor,
              errorStyle: const TextStyle(
                color: Colors.red,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _settingRow({
    required IconData icon,
    required String title,
    Widget? trailing,
    String? trailingText,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 22, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          if (trailing != null) trailing,
          if (trailingText != null)
            Text(
              trailingText,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                context.tr('logout_confirm'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final authProvider = context.read<app_auth.AuthProvider>();
                    final navigator = Navigator.of(context);

                    await authProvider.logout();
                    if (!mounted) return;

                    navigator.pushNamedAndRemoveUntil(
                      "/login",
                          (_) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    context.tr('logout'),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A2B49),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(context.tr('cancel')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
