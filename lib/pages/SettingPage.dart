import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wajeeh/widgets/app_footer.dart';
import '../providers/auth_provider.dart' as myAuth;
import '../providers/theme_provider.dart';
import '../localization/app_localizations.dart';
import 'PrivacyPolicyPage.dart';
import 'TermsPage.dart';
import 'my_preference_page.dart';
import 'saved_itinerary_screen.dart';

class SettingPage extends StatelessWidget {
  const SettingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = theme.brightness == Brightness.dark;
    final auth = Provider.of<myAuth.AuthProvider>(context);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<myAuth.AuthProvider>().loadUserProfile();
    });

    final String name = auth.fullName ?? context.tr('user');
    final String email = auth.email ?? context.tr('no_email');

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(width: 40),
                    Text(
                      context.tr('setting'),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(context, '/notifications');
                      },
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Icon(
                            Icons.notifications,
                            size: 28,
                            color: theme.colorScheme.primary,
                          ),
                          PositionedDirectional(
                            end: -2,
                            top: -2,
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Text(
                                "3",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.white,
                      child: CircleAvatar(
                        radius: 36,
                        backgroundImage:
                            (auth.photoUrl != null && auth.photoUrl!.isNotEmpty)
                            ? NetworkImage(auth.photoUrl!)
                            : const AssetImage("images/defaultUserProfile.png")
                                  as ImageProvider,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          email,
                          style: TextStyle(
                            fontSize: 13,
                            color:
                                theme.textTheme.bodySmall?.color ??
                                Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  context.tr('personal_info'),
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.textTheme.bodySmall?.color ?? Colors.black54,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _profileDropdownTile(context, theme),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: Text(
                  context.tr('security'),
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.textTheme.bodySmall?.color ?? Colors.black54,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _settingTile(
                context: context,
                icon: Icons.lock,
                title: context.tr('change_password'),
                onTap: () {
                  Navigator.pushNamed(context, '/ChangePass');
                },
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: Text(
                  context.tr('general'),
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.textTheme.bodySmall?.color ?? Colors.black54,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _settingTile(
                context: context,
                icon: Icons.translate,
                title: context.tr('language'),
                onTap: () {
                  Navigator.pushNamed(context, '/languagePreference');
                },
              ),
              _settingTile(
                context: context,
                icon: Icons.chat_bubble_outline,
                title: context.tr('feedback'),
                onTap: () {
                  Navigator.pushNamed(context, '/user_feedback');
                },
              ),
              _settingTile(
                context: context,
                icon: Icons.location_on_outlined,
                title: context.tr('edit_your_location'),
                onTap: () {
                  Navigator.pushNamed(context, '/editLocation');
                },
              ),
              _settingTile(
                context: context,
                icon: Icons.bookmark_border,
                title: context.tr('saved_itinerary'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SavedItineraryScreen(),
                    ),
                  );
                },
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: Text(
                  context.tr('about'),
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.textTheme.bodySmall?.color ?? Colors.black54,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Theme(
                data: Theme.of(
                  context,
                ).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                  childrenPadding: const EdgeInsetsDirectional.only(start: 72, end: 16),
                  leading: Icon(
                    Icons.description_outlined,
                    color: theme.colorScheme.primary,
                  ),
                  title: Text(
                    context.tr('policies_and_terms'),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  trailing: Icon(
                    Icons.expand_more,
                    color: theme.colorScheme.primary,
                  ),
                  children: [
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () async {
                          await Future.delayed(
                            const Duration(milliseconds: 150),
                          );
                          Navigator.push(
                            context,
                            PageRouteBuilder(
                              opaque: false,
                              barrierColor: Colors.transparent,
                              pageBuilder: (_, __, ___) =>
                                  const PrivacyPolicyPage(),
                            ),
                          );
                        },
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            Icons.privacy_tip_outlined,
                            color: themeProvider.isDarkMode
                                ? const Color(0xFFF5A623)
                                : const Color(0xFF1A2B49),
                            size: 22,
                          ),
                          title: Text(
                            context.tr('privacy_policy'),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: themeProvider.isDarkMode
                                  ? Colors.white
                                  : const Color(0xFF1A2B49),
                            ),
                          ),
                          trailing: Icon(
                            Icons.chevron_right,
                            color: themeProvider.isDarkMode
                                ? const Color(0xFFF5A623)
                                : const Color(0xFF1A2B49),
                          ),
                        ),
                      ),
                    ),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () async {
                          await Future.delayed(
                            const Duration(milliseconds: 150),
                          );
                          Navigator.push(
                            context,
                            PageRouteBuilder(
                              opaque: false,
                              barrierColor: Colors.transparent,
                              pageBuilder: (_, __, ___) => const TermsPage(),
                            ),
                          );
                        },
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            Icons.description_outlined,
                            color: themeProvider.isDarkMode
                                ? const Color(0xFFF5A623)
                                : const Color(0xFF1A2B49),
                            size: 22,
                          ),
                          title: Text(
                            context.tr('terms'),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: themeProvider.isDarkMode
                                  ? Colors.white
                                  : const Color(0xFF1A2B49),
                            ),
                          ),
                          trailing: Icon(
                            Icons.chevron_right,
                            color: themeProvider.isDarkMode
                                ? const Color(0xFFF5A623)
                                : const Color(0xFF1A2B49),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Text(
                  context.tr('preferences'),
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.textTheme.bodySmall?.color ?? Colors.black54,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ListTile(
                leading: Icon(
                  themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                  color: theme.colorScheme.primary,
                ),
                title: Text(
                  context.tr('dark_mode'),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                subtitle: Text(
                  themeProvider.isDarkMode ? context.tr('on') : context.tr('off'),
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.textTheme.bodySmall?.color ?? Colors.black54,
                  ),
                ),
                trailing: Switch(
                  value: themeProvider.isDarkMode,
                  onChanged: (v) => themeProvider.setDarkMode(v),
                  activeTrackColor: theme.colorScheme.primary.withOpacity(0.5),
                  activeThumbColor: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => _showLogoutDialog(context),
                    child: Text(
                      context.tr('logout'),
                      style: TextStyle(
                        color: isDark ? const Color(0xFF1A2B49) : Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const AppFooter(currentIndex: 4),
    );
  }
}

void _showLogoutDialog(BuildContext context) {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;
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
                  await context.read<myAuth.AuthProvider>().logout();
                  if (!context.mounted) return;
                  Navigator.pushNamedAndRemoveUntil(
                    context,
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
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  context.tr('cancel'),
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _settingTile({
  required BuildContext context,
  required IconData icon,
  required String title,
  VoidCallback? onTap,
}) {
  final theme = Theme.of(context);
  return ListTile(
    leading: Icon(icon, color: theme.colorScheme.primary),
    title: Text(
      title,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: theme.colorScheme.onSurface,
      ),
    ),
    trailing: Icon(Icons.chevron_right, color: theme.colorScheme.primary),
    onTap: onTap,
  );
}

Widget _profileDropdownTile(BuildContext context, ThemeData theme) {
  return Theme(
    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
    child: ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 16),
      childrenPadding: const EdgeInsetsDirectional.only(start: 72, end: 16),
      leading: Icon(Icons.person, color: theme.colorScheme.primary),
      title: Text(
        context.tr('profile'),
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: theme.colorScheme.onSurface,
        ),
      ),
      trailing: Icon(Icons.chevron_right, color: theme.colorScheme.primary),
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            context.tr('edit_profile'),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurface,
            ),
          ),
          onTap: () {
            Navigator.pushNamed(context, '/profile');
          },
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            context.tr('my_preference'),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurface,
            ),
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MyPreferencePage()),
            );
          },
        ),
      ],
    ),
  );
}
