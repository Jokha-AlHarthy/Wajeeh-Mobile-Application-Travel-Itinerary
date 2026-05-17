import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/admin_footer.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'edit_user_info_screen.dart';
import 'AdminUserTripsPage.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../localization/app_localizations.dart';
import '../services/functions_service.dart';
import '../utils/user_profile_image.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  static const Color cream = Color(0xFFF7F1E8);
  static const Color cardBg = Color(0xFFFDF7EE);
  static const Color darkBlue = Color(0xFF0C1C3D);
  String searchQuery = "";

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<QueryDocumentSnapshot> _usersCache = const [];

  String? _selectedRole;
  bool? _showActive;
  bool _forcePasswordChange = false;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _functions = FunctionsService.instance;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  String _normalizeQuery(String v) => v.trim().toLowerCase();

  String _userPlaceName(Map<String, dynamic> data) {
    final location = data["location"];
    if (location is Map) return (location["placeName"] ?? "").toString();
    return "";
  }

  String _userAutocompleteLabel(Map<String, dynamic> data) {
    final name = (data["fullName"] ?? "").toString().trim();
    return name.isEmpty ? "—" : name;
  }

  Map<String, dynamic> _userDocData(QueryDocumentSnapshot doc) {
    final raw = doc.data();
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return {};
  }

  String _displayFullName(Map<String, dynamic> data, String docId) {
    final name = (data["fullName"] ?? "").toString().trim();
    if (name.isNotEmpty) return name;
    final email = (data["email"] ?? "").toString().trim();
    if (email.isNotEmpty) return email;
    return docId;
  }

  String _displayEmail(Map<String, dynamic> data) {
    final email = (data["email"] ?? "").toString().trim();
    return email.isEmpty ? "—" : email;
  }

  String _displayRole(BuildContext context, Map<String, dynamic> data) {
    final roleKey = (data["role"] ?? "user").toString().trim().toLowerCase();
    if (roleKey == "admin" || roleKey == "user") {
      return context.tr(roleKey);
    }
    return roleKey.isEmpty ? context.tr("user") : roleKey;
  }

  Iterable<QueryDocumentSnapshot> _usersForAutocomplete() sync* {
    final q = _normalizeQuery(_searchController.text);
    final docs = _showActive == null
        ? _usersCache
        : _usersCache.where((doc) {
            final data = _userDocData(doc);
            final Timestamp? lastSeen = data["lastSeen"];
            return _isUserActive(lastSeen) == _showActive;
          });

    for (final doc in docs) {
      final data = _userDocData(doc);
      final name = (data["fullName"] ?? "").toString().toLowerCase();
      final email = (data["email"] ?? "").toString().toLowerCase();

      if (q.isEmpty) {
        yield doc;
        continue;
      }

      if (name.contains(q) || email.contains(q)) {
        yield doc;
      }
    }
  }

  Future<Map<String, int>> _fetchTripCountsForUsers(List<String> userIds) async {
    final out = <String, int>{};
    for (final id in userIds) {
      out[id] = 0;
    }

    if (userIds.isEmpty) return out;

    const chunkSize = 30; // Firestore whereIn limit
    int totalTripsByUserId = 0;

    for (var i = 0; i < userIds.length; i += chunkSize) {
      final chunk = userIds.sublist(
        i,
        (i + chunkSize > userIds.length) ? userIds.length : i + chunkSize,
      );
      final snap = await _firestore
          .collection('trips')
          .where('userId', whereIn: chunk)
          .get();
      totalTripsByUserId += snap.docs.length;
      for (final d in snap.docs) {
        final data = d.data();
        final uid = data['userId']?.toString();
        if (uid != null && out.containsKey(uid)) {
          out[uid] = (out[uid] ?? 0) + 1;
        }
      }
    }

    // Fallback (legacy): some projects store uid under 'uid'
    if (totalTripsByUserId == 0) {
      for (var i = 0; i < userIds.length; i += chunkSize) {
        final chunk = userIds.sublist(
          i,
          (i + chunkSize > userIds.length) ? userIds.length : i + chunkSize,
        );
        final snap = await _firestore
            .collection('trips')
            .where('uid', whereIn: chunk)
            .get();
        for (final d in snap.docs) {
          final data = d.data();
          final uid = data['uid']?.toString();
          if (uid != null && out.containsKey(uid)) {
            out[uid] = (out[uid] ?? 0) + 1;
          }
        }
      }
    }

    return out;
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w\-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  bool _isUserActive(Timestamp? lastSeen) {
    if (lastSeen == null) return false;

    final sixMonthsAgo = Timestamp.fromDate(
      DateTime.now().subtract(const Duration(days: 180)),
    );

    return lastSeen.compareTo(sixMonthsAgo) >= 0;
  }

  Future<void> _addUser() async {
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();

    if (username.isEmpty || email.isEmpty || _selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('please_fill_all_fields')),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!_isValidEmail(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('invalid_email')),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final callable = _functions.httpsCallable('createUserWithResetEmail');

      await callable.call(<String, dynamic>{
        'fullName': username,
        'email': email,
        'role': _selectedRole!,
        'forcePasswordChange': _forcePasswordChange,
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('user_added_successfully')),
          backgroundColor: Colors.green,
        ),
      );

      _usernameController.clear();
      _emailController.clear();

      setState(() {
        _selectedRole = null;
        _forcePasswordChange = false;
      });
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;

      String message;

      switch (e.code) {
        case 'not-found':
          message = context.tr('error_cloud_function_not_found');
          break;
        case 'already-exists':
          message = context.tr('error_email_in_use');
          break;
        case 'permission-denied':
          message = context.tr('error_operation_not_allowed');
          break;
        case 'unauthenticated':
          message = context.tr('error_not_logged_in');
          break;
        case 'invalid-argument':
          message = context.tr('error_generic');
          break;
        default:
          final codeLower = e.code.toLowerCase();
          final msgLower = (e.message ?? '').toLowerCase();

          if (codeLower.contains('not-found') ||
              msgLower.contains('not found')) {
            message = context.tr('error_cloud_function_not_found');
          } else if (e.message?.isNotEmpty == true) {
            message = e.message!;
          } else {
            message = context.tr('error_generic');
          }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${context.tr('error')}: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _timeAgo(BuildContext context, DateTime date) {
    final difference = DateTime.now().difference(date);

    if (difference.inMinutes < 60) {
      return "${difference.inMinutes}${context.tr('time_m_ago_suffix')}";
    } else if (difference.inHours < 24) {
      return "${difference.inHours}${context.tr('time_h_ago_suffix')}";
    } else if (difference.inDays < 30) {
      return "${difference.inDays}${context.tr('time_d_ago_suffix')}";
    } else {
      return "${(difference.inDays / 30).floor()}${context.tr('time_mo_ago_suffix')}";
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      backgroundColor: themeProvider.isDarkMode
          ? const Color(0xFF3F4E67)
          : cream,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                children: [
                  Image.asset("images/logo.png", height: 70),
                  const SizedBox(height: 8),
                  Text(
                    context.tr('admin_dashboard'),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: themeProvider.isDarkMode
                          ? const Color(0xFFF5A623)
                          : darkBlue,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: themeProvider.isDarkMode
                          ? const Color(0xFF566C8A)
                          : cardBg,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: themeProvider.isDarkMode
                            ? const Color(0xFF8FA9C4)
                            : Colors.grey.shade400,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          context.tr('add_user'),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: darkBlue,
                          ),
                        ),
                        const SizedBox(height: 14),
                        _buildTextField(
                          controller: _usernameController,
                          hint: context.tr('username'),
                        ),
                        const SizedBox(height: 10),
                        _buildTextField(
                          controller: _emailController,
                          hint: context.tr('email'),
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 10),
                        _buildRoleDropdown(),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Checkbox(
                              value: _forcePasswordChange,
                              activeColor: darkBlue,
                              onChanged: (value) {
                                setState(() {
                                  _forcePasswordChange = value ?? false;
                                });
                              },
                            ),
                            Expanded(
                              child: Text(
                                context.tr('force_password_change'),
                                style: TextStyle(
                                  color: darkBlue,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _addUser,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: darkBlue,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(context.tr('add_user')),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('all_users'),
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: themeProvider.isDarkMode
                              ? Colors.white
                              : darkBlue,
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _showActive = null;
                              });
                            },
                            child: Row(
                              children: [
                                const CircleAvatar(
                                  radius: 5,
                                  backgroundColor: Colors.blue,
                                ),
                                const SizedBox(width: 6),
                                Text(context.tr('all')),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _showActive = true;
                              });
                            },
                            child: Row(
                              children: [
                                const CircleAvatar(
                                  radius: 5,
                                  backgroundColor: Color(0xFF2F6C32),
                                ),
                                const SizedBox(width: 6),
                                Text(context.tr('active')),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _showActive = false;
                              });
                            },
                            child: Row(
                              children: [
                                const CircleAvatar(
                                  radius: 5,
                                  backgroundColor: Colors.red,
                                ),
                                const SizedBox(width: 6),
                                Text(context.tr('non_active')),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildSearchBar(),
                  const SizedBox(height: 14),
                  _buildUsersTable(),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: const AdminFooter(currentIndex: 1),
    );
  }

  Widget _buildSearchBar() {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final borderColor = isDark ? const Color(0xFF8FA9C4) : Colors.grey.shade400;
    final textColor = isDark ? Colors.white : Colors.black;
    return RawAutocomplete<QueryDocumentSnapshot>(
      textEditingController: _searchController,
      focusNode: _searchFocusNode,
      displayStringForOption: (opt) {
        final data = opt.data() as Map<String, dynamic>;
        return _userAutocompleteLabel(data);
      },
      optionsBuilder: (value) {
        final q = _normalizeQuery(value.text);
        if (q.isEmpty) return const Iterable<QueryDocumentSnapshot>.empty();
        return _usersForAutocomplete().take(8);
      },
      onSelected: (opt) {
        final data = opt.data() as Map<String, dynamic>;
        final name = (data["fullName"] ?? "").toString().trim();
        _searchController.text = name;
        _searchController.selection = TextSelection.fromPosition(
          TextPosition(offset: _searchController.text.length),
        );
        setState(() => searchQuery = _normalizeQuery(name));
      },
      fieldViewBuilder: (context, textController, focusNode, onFieldSubmitted) {
        return TextField(
          controller: textController,
          focusNode: focusNode,
          onChanged: (value) {
            setState(() => searchQuery = _normalizeQuery(value));
          },
          style: TextStyle(color: textColor),
          decoration: InputDecoration(
            hintText: context.tr('search'),
            hintStyle: TextStyle(color: textColor.withValues(alpha: 0.65)),
            prefixIcon: Icon(Icons.search, color: textColor),
            suffixIcon: textController.text.trim().isEmpty
                ? null
                : IconButton(
                    onPressed: () {
                      textController.clear();
                      setState(() => searchQuery = "");
                    },
                    icon: Icon(Icons.close, color: textColor),
                  ),
            filled: true,
            fillColor: isDark ? const Color(0xFF5F7594) : Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: borderColor, width: 1.4),
            ),
          ),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            color: Colors.transparent,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Container(
                margin: const EdgeInsets.only(top: 6),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF566C8A) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: ListView.separated(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: options.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    color: borderColor.withValues(alpha: 0.4),
                  ),
                  itemBuilder: (context, index) {
                    final opt = options.elementAt(index);
                    final data = opt.data() as Map<String, dynamic>;
                    final name = (data["fullName"] ?? "").toString().trim();
                    final email = (data["email"] ?? "").toString().trim();
                    final place = _userPlaceName(data).trim();
                    return ListTile(
                      dense: true,
                      title: Text(
                        name.isEmpty ? email : name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: textColor),
                      ),
                      subtitle: (email.isEmpty && place.isEmpty)
                          ? null
                          : Text(
                              [email, place]
                                  .where((s) => s.isNotEmpty)
                                  .join(" • "),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: textColor.withValues(alpha: 0.75),
                                fontSize: 12,
                              ),
                            ),
                      onTap: () => onSelected(opt),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    bool obscure = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: context.watch<ThemeProvider>().isDarkMode
            ? const Color(0xFF5F7594)
            : Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildRoleDropdown() {
    return DropdownButtonFormField<String>(
      alignment: AlignmentDirectional.centerStart,
      initialValue: _selectedRole,
      decoration: InputDecoration(
        filled: true,
        fillColor: context.watch<ThemeProvider>().isDarkMode
            ? const Color(0xFF5F7594)
            : Colors.white,
        hintText: context.tr('role'),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      items: [
        DropdownMenuItem(value: "user", child: Text(context.tr('user'))),
        DropdownMenuItem(value: "admin", child: Text(context.tr('admin'))),
      ],
      onChanged: (value) {
        setState(() {
          _selectedRole = value;
        });
      },
    );
  }

  Widget _buildUsersTable() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const CircularProgressIndicator();
        }

        final allUsers = snapshot.data!.docs;
        _usersCache = allUsers;

        final users = (_showActive == null ? allUsers : allUsers.where((doc) {
          final data = _userDocData(doc);
          final Timestamp? lastSeen = data["lastSeen"];
          return _isUserActive(lastSeen) == _showActive;
        })).where((doc) {
          final data = _userDocData(doc);
          final name = (data["fullName"] ?? "").toString().toLowerCase();
          final email = (data["email"] ?? "").toString().toLowerCase();

          if (searchQuery.isEmpty) return true;
          if (name == searchQuery || email == searchQuery) return true;
          return name.contains(searchQuery) || email.contains(searchQuery);
        }).toList();

        return FutureBuilder<Map<String, int>>(
          future: _fetchTripCountsForUsers(users.map((e) => e.id).toList()),
          builder: (context, tripsSnap) {
            final tripCounts = tripsSnap.data ?? const <String, int>{};
            return Column(
              children: users.map((doc) {
            final data = _userDocData(doc);

            final String fullName = _displayFullName(data, doc.id);
            final String email = _displayEmail(data);
            final String role = _displayRole(context, data);
            final String? photoURL = data["photoUrl"]?.toString();
            final String? profileB64 =
                data["profilePhotoBase64"]?.toString();
            final Timestamp? createdAt = data["createdAt"] is Timestamp
                ? data["createdAt"] as Timestamp
                : null;
            final Timestamp? lastSeen = data["lastSeen"] is Timestamp
                ? data["lastSeen"] as Timestamp
                : null;

            final bool isActiveUser = _isUserActive(lastSeen);
            final avatar = resolveProfileImageProvider(
              photoUrl: photoURL,
              profilePhotoBase64: profileB64,
            );
            final showAvatarIcon = !hasCustomProfileImage(
              photoUrl: photoURL,
              profilePhotoBase64: profileB64,
            );

            final joinedDate = createdAt != null
                ? "${createdAt.toDate().day}/${createdAt.toDate().month}/${createdAt.toDate().year}"
                : "-";

            final lastActiveText = lastSeen != null
                ? _timeAgo(context, lastSeen.toDate())
                : context.tr('recently');

            final tripsCount = tripCounts[doc.id] ?? 0;

            return Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.watch<ThemeProvider>().isDarkMode
                    ? const Color(0xFF566C8A)
                    : const Color(0xFFF5A623),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: context.watch<ThemeProvider>().isDarkMode
                      ? const Color(0xFF8FA9C4)
                      : Colors.black,
                  width: 1.2,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.grey.shade300,
                        backgroundImage: showAvatarIcon ? null : avatar,
                        child: showAvatarIcon
                            ? const Icon(Icons.person, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    fullName,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 5,
                                      backgroundColor: isActiveUser
                                          ? const Color(0xFF2F6C32)
                                          : Colors.red,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      isActiveUser
                                          ? context.tr('active')
                                          : context.tr('non_active'),
                                      style: TextStyle(
                                        color: isActiveUser
                                            ? const Color(0xFF2F6C32)
                                            : Colors.red,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              email,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              role,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,

                    children: [
                      Text(
                        "${context.tr('last_active')}: $lastActiveText",
                        style: const TextStyle(fontSize: 13),
                      ),
                      Text(
                        "${context.tr('joined')}: $joinedDate",
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AdminUserTripsPage(userId: doc.id),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "${context.tr('preferences')}: $tripsCount",
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: SizedBox(
                      height: 36,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EditUserInfoScreen(uid: doc.id),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: darkBlue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(context.tr('edit')),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
          },
        );
      },
    );
  }


}
