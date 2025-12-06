import 'package:flutter/material.dart';
import 'ai_trip_loading.dart';
import 'notifications_screen.dart';

class ReviewSummaryScreen extends StatefulWidget {
  const ReviewSummaryScreen({super.key});

  @override
  State<ReviewSummaryScreen> createState() => _ReviewSummaryScreenState();
}

class _ReviewSummaryScreenState extends State<ReviewSummaryScreen> {
  final TextEditingController _tripNameController = TextEditingController(
    text: "2025 May",
  );

  String _destination = "Oman";
  String _travellers = "With Family";
  String _dates = "21–24 May 2025";
  String _budget = "Cheap";

  final List<String> _allInterests = [
    "Relaxing",
    "Road Trip",
    "Historical",
    "Food Tourism",
  ];

  @override
  void dispose() {
    _tripNameController.dispose();
    super.dispose();
  }

  void _openLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const TripLoadingDialog(),
    );

    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Trip generated")));
      }
    });
  }

  Widget _rowItem(
    IconData icon,
    String title,
    String value,
    VoidCallback onEdit,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xff1A2B49)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Text(value, style: const TextStyle(color: Color(0xff1A2B49))),
              ],
            ),
          ),
          InkWell(
            onTap: onEdit,
            child: const Icon(Icons.edit, size: 20, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  void _showEditValueDialog(
    String title,
    String current,
    ValueChanged<String> onSaved,
  ) {
    final controller = TextEditingController(text: current);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 18,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 18,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Edit $title",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                decoration: InputDecoration(hintText: title),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text("Cancel"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        onSaved(controller.text.trim());
                        Navigator.pop(ctx);
                      },
                      child: const Text("Save"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddInterestDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text("Add Interest"),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: "Enter new interest"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                final text = controller.text.trim();
                if (text.isNotEmpty && !_allInterests.contains(text)) {
                  setState(() {
                    _allInterests.add(text);
                  });
                }
                Navigator.pop(ctx);
              },
              child: const Text("Add"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5EFE4),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        centerTitle: true,
        title: const Text(
          "Review Summary",
          style: TextStyle(
            color: Color(0xff1A2B49),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),

        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
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
                  const Icon(
                    Icons.notifications,
                    size: 28,
                    color: Colors.black,
                  ),
                  Positioned(
                    right: -1,
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
          ),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),

            const Text(
              "Trip Name",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xff1A2B49),
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Color(0xff1A2B49)),
              ),
              child: TextField(
                controller: _tripNameController,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: "Trip name (e.g. 2025 May)",
                ),
              ),
            ),
            const SizedBox(height: 22),
            _rowItem(
              Icons.location_on_outlined,
              "Destination",
              _destination,
              () {
                _showEditValueDialog("Destination", _destination, (v) {
                  setState(() => _destination = v);
                });
              },
            ),
            _rowItem(
              Icons.group_outlined,
              "Choose your traveler",
              _travellers,
              () {
                _showEditValueDialog("Traveler", _travellers, (v) {
                  setState(() => _travellers = v);
                });
              },
            ),
            _rowItem(Icons.date_range_outlined, "Travel Dates", _dates, () {
              _showEditValueDialog("Dates", _dates, (v) {
                setState(() => _dates = v);
              });
            }),
            _rowItem(Icons.wallet_outlined, "Travel Budget", _budget, () {
              _showEditValueDialog("Budget", _budget, (v) {
                setState(() => _budget = v);
              });
            }),
            const SizedBox(height: 6),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Interest",
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
                InkWell(
                  onTap: _showAddInterestDialog,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Color(0xff1A2B49)),
                    ),
                    child: const Icon(Icons.add, size: 20),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 16,
                      runSpacing: 13,
                      children: _allInterests.map((interest) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xff1A2B49)),
                          ),
                          child: Text(
                            interest,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xff1A2B49),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _openLoadingDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff1A2B49),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text(
                  "Generate Trip",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),

            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }
}
