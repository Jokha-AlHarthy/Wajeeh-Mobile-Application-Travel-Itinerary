import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../localization/app_localizations.dart';

class AdminUserTripsPage extends StatefulWidget {
  final String userId;

  const AdminUserTripsPage({super.key, required this.userId});

  @override
  State<AdminUserTripsPage> createState() => _AdminUserTripsPageState();
}

class _AdminUserTripsPageState extends State<AdminUserTripsPage> {
  static const Color cream = Color(0xFFF7F1E8);
  static const Color cardBg = Color(0xFFFDF7EE);
  static const Color darkBlue = Color(0xFF0C1C3D);
  static const Color accentOrange = Color(0xFFF5A623);

  final TextEditingController _searchController = TextEditingController();
  String searchQuery = "";

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatDateTime(Timestamp? ts) {
    if (ts == null) return "-";
    final d = ts.toDate();
    return "${d.day}/${d.month}/${d.year}  ${d.hour}:${d.minute.toString().padLeft(2, '0')}";
  }

  String _tripTitle(BuildContext context, Map<String, dynamic> data) {
    final country = data['country']?.toString().trim();
    final year = data['year']?.toString().trim();

    if ((country ?? '').isNotEmpty && (year ?? '').isNotEmpty) {
      return "$country • $year";
    }

    if ((country ?? '').isNotEmpty) return country!;
    return context.tr('trip');
  }

  String _getBudget(BuildContext context, Map<String, dynamic> data) {
    final value = data['budget']?.toString().trim();

    if (value == null || value.isEmpty) return "-";

    return context.tr(value);
  }

  String _getTripDetails(BuildContext context, Map<String, dynamic> data) {
    final parts = <String>[];

    final tripType = data['tripType'];
    if (tripType is List && tripType.isNotEmpty) {
      parts.add(
        tripType
            .map((e) => context.tr(e.toString()))
            .where((s) => s.isNotEmpty)
            .join(", "),
      );
    }

    final interest = data['interest'];
    if (interest is List && interest.isNotEmpty) {
      parts.add(
        interest
            .map((e) => context.tr(e.toString()))
            .where((s) => s.isNotEmpty)
            .join(", "),
      );
    }

    return parts.isEmpty ? "-" : parts.join(" • ");
  }

  Widget _buildSearchBar({required bool isDark}) {
    final textColor = isDark ? Colors.white : darkBlue;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.08),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
        onChanged: (value) {
          setState(() {
            searchQuery = value.trim().toLowerCase();
          });
        },
        decoration: InputDecoration(
          hintText: context.tr('search_country_year'),
          hintStyle: TextStyle(
            color: isDark ? Colors.white70 : Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Icon(Icons.search, color: accentOrange),
          suffixIcon: searchQuery.isEmpty
              ? null
              : IconButton(
                  icon: Icon(Icons.close, color: textColor),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      searchQuery = "";
                    });
                  },
                ),
          filled: true,
          fillColor: isDark ? const Color(0xFF566C8A) : Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(
              color: isDark ? const Color(0xFF8FA9C4) : Colors.grey.shade200,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: accentOrange, width: 1.6),
          ),
        ),
      ),
    );
  }

  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
  }) {
    final textColor = isDark ? Colors.white : darkBlue;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: accentOrange),
        const SizedBox(width: 10),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(
                color: textColor,
                fontSize: 13.5,
                height: 1.35,
              ),
              children: [
                TextSpan(
                  text: "$label: ",
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                TextSpan(
                  text: value,
                  style: TextStyle(
                    color: isDark ? Colors.white70 : darkBlue.withValues(alpha: 0.78),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _emptyMessage({
    required String message,
    required bool isDark,
  }) {
    final textColor = isDark ? Colors.white : darkBlue;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF566C8A) : cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF8FA9C4) : Colors.grey.shade300,
        ),
      ),
      child: Column(
        children: [
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: accentOrange.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.travel_explore,
              color: accentOrange,
              size: 28,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _tripCard({
    required BuildContext context,
    required Map<String, dynamic> data,
    required bool isDark,
  }) {
    final textColor = isDark ? Colors.white : darkBlue;
    final cardColor = isDark ? const Color(0xFF566C8A) : Colors.white;
    final createdAt = data['createdAt'] as Timestamp?;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF8FA9C4) : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.08),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(
              width: 8,
              decoration: const BoxDecoration(
                color: accentOrange,
                borderRadius: BorderRadius.horizontal(
                  left: Radius.circular(20),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          height: 42,
                          width: 42,
                          decoration: BoxDecoration(
                            color: accentOrange.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.public,
                            color: accentOrange,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _tripTitle(context, data),
                            style: TextStyle(
                              color: textColor,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _infoRow(
                      icon: Icons.account_balance_wallet_outlined,
                      label: context.tr('budget'),
                      value: _getBudget(context, data),                      isDark: isDark,
                    ),
                    const SizedBox(height: 10),
                    _infoRow(
                      icon: Icons.category_outlined,
                      label: context.tr('type_interests'),
                      value: _getTripDetails(context, data),                      isDark: isDark,
                    ),
                    const SizedBox(height: 10),
                    _infoRow(
                      icon: Icons.schedule,
                      label: context.tr('created'),
                      value: _formatDateTime(createdAt),
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;

    final bg = isDark ? const Color(0xFF3F4E67) : cream;
    final appBarColor = isDark ?  darkBlue.withValues(alpha: 0) : const Color(0xFFFAF3E7);
    final appBarTitleColor = isDark ? Colors.white : darkBlue;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: appBarColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: appBarTitleColor),
        title: Text(
          context.tr('user_trips_details'),
          style: TextStyle(
            color: appBarTitleColor,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 26),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 6),
                  Text(
                    context.tr('user_trips_description'),
                    style: TextStyle(
                      color: isDark ? Colors.white70 : darkBlue.withValues(alpha: 0.7),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 18),
                  _buildSearchBar(isDark: isDark),
                  const SizedBox(height: 22),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('trips')
                        .where('userId', isEqualTo: widget.userId)
                        .snapshots(),
                    builder: (context, tripSnap) {
                      if (tripSnap.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 32),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      if (!tripSnap.hasData || tripSnap.data!.docs.isEmpty) {
                        return _emptyMessage(
                          message: context.tr('no_trips_user'),
                          isDark: isDark,
                        );
                      }

                      final allTrips = tripSnap.data!.docs.toList();

                      allTrips.sort((a, b) {
                        final aData = a.data() as Map<String, dynamic>;
                        final bData = b.data() as Map<String, dynamic>;

                        final aCreated = aData['createdAt'];
                        final bCreated = bData['createdAt'];

                        final aDate = aCreated is Timestamp
                            ? aCreated.toDate()
                            : DateTime(1970);
                        final bDate = bCreated is Timestamp
                            ? bCreated.toDate()
                            : DateTime(1970);

                        return bDate.compareTo(aDate);
                      });

                      final filteredTrips = allTrips.where((doc) {
                        if (searchQuery.isEmpty) return true;

                        final data = doc.data() as Map<String, dynamic>;

                        final country =
                            (data['country'] ?? '').toString().toLowerCase();
                        final year =
                            (data['year'] ?? '').toString().toLowerCase();

                        return country.contains(searchQuery) ||
                            year.contains(searchQuery);
                      }).toList();

                      if (filteredTrips.isEmpty) {
                        return _emptyMessage(
                          message: context.tr('no_trips_search'),
                          isDark: isDark,
                        );
                      }

                      return Column(
                        children: filteredTrips.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _tripCard(
                              context: context,
                              data: data,
                              isDark: isDark,
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
