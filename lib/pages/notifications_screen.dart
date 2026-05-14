import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'user_feedback_screen.dart';
import '../localization/app_localizations.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import '../providers/travel_provider.dart';
import 'trip_detail_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final user = FirebaseAuth.instance.currentUser;
  Timer? _timer;

  String _formatTime(dynamic timestamp) {
    if (timestamp == null) return "";

    try {
      final date = (timestamp as Timestamp).toDate();

      return "${date.day}/${date.month}/${date.year}  ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
    } catch (_) {
      return "";
    }
  }

  @override
  void initState() {
    super.initState();

    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _markAllAsRead() async {
    final snapshot = await FirebaseFirestore.instance
        .collection("notifications")
        .where("userId", isEqualTo: user?.uid)
        .where("isRead", isEqualTo: false)
        .get();

    for (var doc in snapshot.docs) {
      await doc.reference.update({
        "isRead": true,
      });
    }
  }

  Future<void> _markAsRead(String id) async {
    await FirebaseFirestore.instance
        .collection("notifications")
        .doc(id)
        .update({
      "isRead": true,
    });
  }

  Future<void> _deleteNotification(String id) async {
    await FirebaseFirestore.instance
        .collection("notifications")
        .doc(id)
        .delete();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(
                        Icons.notifications_none,
                        color: theme.colorScheme.onSurface,
                        size: 26,
                      ),

                      PositionedDirectional(
                        end: -6,
                        top: -6,
                        child: StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection("notifications")
                              .where("userId", isEqualTo: user?.uid)
                              .where("isRead", isEqualTo: false)
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const SizedBox();
                            }

                            final now = DateTime.now();

                            final count = snapshot.data!.docs.where((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              final scheduledAt = data["scheduledAt"];

                              if (scheduledAt == null) return true;

                              if (scheduledAt is Timestamp) {
                                return !scheduledAt.toDate().isAfter(now);
                              }

                              return true;
                            }).length;

                            if (count == 0) {
                              return const SizedBox();
                            }

                            return Container(
                              width: 18,
                              height: 18,
                              alignment: Alignment.center,
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                count.toString(),
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
                ],
              ),
            ),

            const SizedBox(height: 8),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    context.tr('notifications_center'),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  TextButton(
                    onPressed: _markAllAsRead,
                    child: Text(
                      context.tr("read_all"),
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection("notifications")
                    .where("userId", isEqualTo: user?.uid)
                    .orderBy("createdAt", descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        snapshot.error.toString(),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Text(
                        context.tr("no_notifications"),
                        style: TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontSize: 16,
                        ),
                      ),
                    );
                  }

                  final now = DateTime.now();

                  final docs = snapshot.data!.docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final scheduledAt = data["scheduledAt"];

                    if (scheduledAt == null) return true;

                    if (scheduledAt is Timestamp) {
                      return !scheduledAt.toDate().isAfter(now);
                    }

                    return true;
                  }).toList();

                  if (docs.isEmpty) {
                    return Center(
                      child: Text(
                        context.tr("no_notifications"),
                        style: TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontSize: 16,
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final data = doc.data() as Map<String, dynamic>;

                      final title = data["title"] ?? "";
                      final message = data["message"] ?? "";
                      final isRead = data["isRead"] ?? false;
                      final createdAt = data["createdAt"];
                      final scheduledAt = data["scheduledAt"];
                      final type = data["type"] ?? "";
                      final tripId = data["tripId"]?.toString();
                      final displayTime = type == "trip_plan"
                          ? createdAt
                          : (scheduledAt ?? createdAt);

                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isRead
                              ? theme.scaffoldBackgroundColor
                              : const Color(0xFFFFF3E0),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: theme.colorScheme.primary,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    title,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                ),

                                if (type == "trip_plan" && tripId != null && tripId.isNotEmpty)
                                  IconButton(
                                    tooltip: context.tr("view_trip_details"),
                                    onPressed: () {
                                      final travel = context.read<TravelProvider>();

                                      final index = travel.savedTrips.indexWhere(
                                            (t) => t["id"]?.toString() == tripId,
                                      );

                                      if (index < 0) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text(context.tr("trip_not_found"))),
                                        );
                                        return;
                                      }

                                      final trip = travel.savedTrips[index];

                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => TripDetailScreen(trip: trip),
                                        ),
                                      );
                                    },
                                    icon: Icon(
                                      Icons.open_in_new,
                                      color: theme.colorScheme.primary,
                                      size: 22,
                                    ),
                                  ),
                              ],
                            ),

                            const SizedBox(height: 6),

                            Text(
                              _formatTime(displayTime),
                              style: TextStyle(
                                color: theme.textTheme.bodySmall?.color ??
                                    theme.colorScheme.onSurface
                                        .withValues(alpha: 0.7),
                                fontSize: 13,
                              ),
                            ),

                            const SizedBox(height: 12),

                            Text(
                              message,
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.4,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),

                            const SizedBox(height: 16),

                            if (type == "feedback") ...[
                              SizedBox(
                                width: double.infinity,
                                height: 46,
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const UserFeedbackScreen(),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.amber,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Text(
                                    context.tr("give_feedback"),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 14),
                            ],

                            LayoutBuilder(
                              builder: (context, constraints) {
                                final isSmall = constraints.maxWidth < 320;

                                if (isSmall) {
                                  return Column(
                                    children: [
                                      SizedBox(
                                        width: double.infinity,
                                        child: _buildReadButton(
                                          theme,
                                          doc.id,
                                          isRead,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      SizedBox(
                                        width: double.infinity,
                                        child: _buildDeleteButton(
                                          theme,
                                          doc.id,
                                        ),
                                      ),
                                    ],
                                  );
                                }

                                return Row(
                                  children: [
                                    Expanded(
                                      child: _buildReadButton(
                                        theme,
                                        doc.id,
                                        isRead,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _buildDeleteButton(
                                        theme,
                                        doc.id,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReadButton(ThemeData theme, String id, bool isRead) {
    return SizedBox(
      height: 46,
      child: ElevatedButton(
        onPressed: isRead ? null : () => _markAsRead(id),
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            isRead ? context.tr("read") : context.tr("mark_as_read"),
            maxLines: 1,
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteButton(ThemeData theme, String id) {
    return SizedBox(
      height: 46,
      child: ElevatedButton(
        onPressed: () => _deleteNotification(id),
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
