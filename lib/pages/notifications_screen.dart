import 'package:flutter/material.dart';
import '../localization/app_localizations.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final List<Map<String, dynamic>> notifications = [
    {
      "titleKey": "notif_passport_expiry_title",
      "timeKey": "notif_passport_expiry_time",
      "bodyKey": "notif_passport_expiry_body",
      "isRead": false,
    },
    {
      "titleKey": "notif_weather_alert_title",
      "timeKey": "notif_weather_alert_time",
      "bodyKey": "notif_weather_alert_body",
      "isRead": false,
    },
    {
      "titleKey": "notif_flight_delayed_title",
      "timeKey": "notif_flight_delayed_time",
      "bodyKey": "notif_flight_delayed_body",
      "isRead": false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  BackButton(color: theme.colorScheme.onSurface),
                  Expanded(
                    child: Center(
                      child: Image.asset(
                        "images/logo.png",
                        height: 34,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.notifications_none,
                    color: theme.colorScheme.onSurface,
                    size: 26,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment:
                isArabic ? Alignment.centerRight : Alignment.centerLeft,
                child: Text(
                  context.tr('notifications_center'),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                itemCount: notifications.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final n = notifications[index];

                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: theme.colorScheme.primary,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr(n["titleKey"] as String),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          context.tr(n["timeKey"] as String),
                          style: TextStyle(
                            color: theme.textTheme.bodySmall?.color ??
                                theme.colorScheme.onSurface.withOpacity(0.7),
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          context.tr(n["bodyKey"] as String),
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.4,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Responsive buttons
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isSmall = constraints.maxWidth < 320;

                            if (isSmall) {
                              return Column(
                                children: [
                                  SizedBox(
                                    width: double.infinity,
                                    child: _buildReadButton(theme, n),
                                  ),
                                  const SizedBox(height: 10),
                                  SizedBox(
                                    width: double.infinity,
                                    child: _buildDeleteButton(theme, index),
                                  ),
                                ],
                              );
                            }

                            return Row(
                              children: [
                                Expanded(child: _buildReadButton(theme, n)),
                                const SizedBox(width: 12),
                                Expanded(child: _buildDeleteButton(theme, index)),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReadButton(ThemeData theme, Map<String, dynamic> n) {
    return SizedBox(
      height: 46,
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            n["isRead"] = true;
          });
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            n["isRead"] == true
                ? context.tr("read")
                : context.tr("mark_as_read"),
            maxLines: 1,
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteButton(ThemeData theme, int index) {
    return SizedBox(
      height: 46,
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            notifications.removeAt(index);
          });
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xffE04F4F),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            context.tr("delete"),
            maxLines: 1,
          ),
        ),
      ),
    );
  }
}
