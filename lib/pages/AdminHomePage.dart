import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart' as app_auth;
import '../widgets/admin_footer.dart';
import '../providers/theme_provider.dart';
import '../localization/app_localizations.dart';
import '../utils/user_profile_image.dart';

class AdminHomePage extends StatelessWidget {
  const AdminHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<app_auth.AuthProvider>();
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      backgroundColor: themeProvider.isDarkMode
          ? const Color(0xFF3F4E67)
          : const Color(0xFFF4EFE7),
      bottomNavigationBar: const AdminFooter(currentIndex: 0),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr("dashboard"),
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: themeProvider.isDarkMode
                              ? Colors.white
                              : const Color(0xFF1E2A44),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        auth.fullName ?? context.tr("admin"),
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFFF5A623),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  CircleAvatar(
                    radius: 25,
                    backgroundImage: _homeProfileProvider(auth),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.43,
                      child: _activeUsersCard(),
                    ),
                    const SizedBox(width: 15),
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.43,
                      child: _nonActiveUsersCard(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 15),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.43,
                      child: _complaintsCard(context),
                    ),
                    const SizedBox(width: 15),
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.43,
                      child: _feedbackCard(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 15),
              Center(
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.43,
                  child: _tripsCard(context),
                ),
              ),
              const SizedBox(height: 30),
              Text(
                context.tr("trending_countries"),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: themeProvider.isDarkMode
                      ? Colors.white
                      : const Color(0xFF1E2A44),
                ),
              ),
              const SizedBox(height: 15),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: themeProvider.isDarkMode
                      ? const Color(0xFF566C8A)
                      : const Color(0xFFEDE6DB),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: _trendingCountriesChart(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  ImageProvider _homeProfileProvider(app_auth.AuthProvider auth) {
    return resolveProfileImageProvider(
      photoUrl: auth.photoUrl,
      profilePhotoBase64: auth.profilePhotoBase64,
    );
  }

  Widget _trendingCountriesChart() {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('trips')
          .get(),
      builder: (context, snapshot) {
        const countries = ['OM', 'KW', 'QA', 'BHR', 'KSA', 'UAE'];

        Map<String, Map<int, int>> data = {
          for (var c in countries)
            c: {2024: 0, 2025: 0, 2026: 0}
        };

        if (snapshot.hasData) {
          for (var doc in snapshot.data!.docs) {
            final d = doc.data() as Map<String, dynamic>;
            final country = d['country'];
            final year = d['year'];

            if (data.containsKey(country) &&
                data[country]!.containsKey(year)) {
              data[country]![year] =
                  data[country]![year]! + 1;
            }
          }
        }

        int maxValue = 1;
        for (var c in countries) {
          for (var y in [2024, 2025, 2026]) {
            if (data[c]![y]! > maxValue) {
              maxValue = data[c]![y]!;
            }
          }
        }

        maxValue += 2;

        return Column(
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.30,
              child: BarChart(
                BarChartData(
                  maxY: maxValue.toDouble(),
                  gridData: FlGridData(show: true),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        interval: 1,
                      ),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              countries[value.toInt()],
                              style: TextStyle(
                                fontSize: 12,
                                color: context.watch<ThemeProvider>().isDarkMode
                                    ? Colors.white
                                    : Colors.black,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: List.generate(
                    countries.length,
                        (index) {
                      final c = countries[index];
                      return _makeGroup(
                        index,
                        data[c]![2024]!.toDouble(),
                        data[c]![2025]!.toDouble(),
                        data[c]![2026]!.toDouble(),
                      );
                    },
                  ),
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      tooltipBgColor: Colors.black87,
                      getTooltipItem:
                          (group, groupIndex, rod, rodIndex) {
                        String year;
                        if (rodIndex == 0) {
                          year = "2024";
                        } else if (rodIndex == 1) {
                          year = "2025";
                        } else {
                          year = "2026";
                        }

                        return BarTooltipItem(
                          '$year\n${rod.toY.toInt()}',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                _Legend(color: Color(0xFF6C63FF), text: "2024"),
                SizedBox(width: 20),
                _Legend(color: Color(0xFFFF6B6B), text: "2025"),
                SizedBox(width: 20),
                _Legend(color: Color(0xFF00C2CB), text: "2026"),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _activeUsersCard() => _usersCountByActivityCard(true);
  Widget _nonActiveUsersCard() => _usersCountByActivityCard(false);

  Widget _usersCountByActivityCard(bool active) {
    final sixMonthsAgo = Timestamp.fromDate(
      DateTime.now().subtract(const Duration(days: 180)),
    );
    final query = active
        ? FirebaseFirestore.instance
            .collection('users')
            .where('lastSeen', isGreaterThanOrEqualTo: sixMonthsAgo)
        : FirebaseFirestore.instance
            .collection('users')
            .where('lastSeen', isLessThan: sixMonthsAgo);

    return FutureBuilder<AggregateQuerySnapshot>(
      future: query.count().get(),
      builder: (context, snapshot) {
        final value = snapshot.hasData ? (snapshot.data!.count ?? 0).toString() : "—";
        return _dashboardCard(
          context,
          active ? context.tr("active_users") : context.tr("non_active_users"),
          value,
          active ? const Color(0xFF1E2F4D) : const Color(0xFFF5A623),
        );
      },
    );
  }

  Widget _tripsCard(BuildContext context) => FutureBuilder<AggregateQuerySnapshot>(
        future: FirebaseFirestore.instance.collection('trips').count().get(),
        builder: (context, snapshot) {
          final count = snapshot.data?.count ?? 0;
          return _dashboardCard(
            context,
            "Total Trips",
            snapshot.hasData ? count.toString() : "—",
            const Color(0xFF1E2F4D),
          );
        },
      );

  Widget _complaintsCard(BuildContext context) => FutureBuilder<AggregateQuerySnapshot>(
    future: FirebaseFirestore.instance
        .collection('feedback')
        .where('category', isEqualTo: 'category_complaints')
        .where('isRead', isEqualTo: false)
        .count()
        .get(),
    builder: (context, snapshot) {
      final count = snapshot.data?.count ?? 0;
      return _dashboardCard(
        context,
        context.tr("pending_complaints"),
        snapshot.hasData ? count.toString() : "—",
        const Color(0xFFF5B546),
      );
    },
  );

  Widget _feedbackCard(BuildContext context) => _simpleCollectionCard(
      'feedback', context.tr("total_feedback"), const Color(0xFF4B5873));

  Widget _simpleCollectionCard(
      String collection, String title, Color color) {
    return FutureBuilder<AggregateQuerySnapshot>(
      future: FirebaseFirestore.instance.collection(collection).count().get(),
      builder: (context, snapshot) {
        final count = snapshot.data?.count ?? 0;
        return _dashboardCard(
          context,
          title,
          snapshot.hasData ? count.toString() : "—",
          color,
        );
      },
    );
  }

  Widget _dashboardCard(
    BuildContext context,
    String title,
    String value,
    Color color, {
    String? subtitle,
  }) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final bool lightBg = !isDark &&
        color.computeLuminance() > 0.55; // pick readable text automatically
    final Color primaryText =
        isDark ? Colors.white : (lightBg ? const Color(0xFF1E2A44) : Colors.white);
    final Color secondaryText = isDark
        ? Colors.white.withValues(alpha: 0.85)
        : (lightBg ? Colors.black54 : Colors.white.withValues(alpha: 0.85));
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: primaryText,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 15),
          Text(
            value,
            style: TextStyle(
              color: primaryText,
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 10),
            Text(
              subtitle,
              style: TextStyle(
                color: secondaryText,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  BarChartGroupData _makeGroup(
      int x, double y1, double y2, double y3) {
    return BarChartGroupData(
      x: x,
      barsSpace: 4,
      barRods: [
        BarChartRodData(
            toY: y1,
            width: 8,
            borderRadius: BorderRadius.circular(4),
            color: const Color(0xFF6C63FF)),
        BarChartRodData(
            toY: y2,
            width: 8,
            borderRadius: BorderRadius.circular(4),
            color: const Color(0xFFFF6B6B)),
        BarChartRodData(
            toY: y3,
            width: 8,
            borderRadius: BorderRadius.circular(4),
            color: const Color(0xFF00C2CB)),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String text;

  const _Legend({required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            color: context.watch<ThemeProvider>().isDarkMode
                ? Colors.white
                : Colors.black,
          ),
        ),
      ],
    );
  }
}
