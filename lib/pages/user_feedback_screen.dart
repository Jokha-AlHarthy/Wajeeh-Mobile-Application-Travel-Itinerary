import 'package:flutter/material.dart';
import 'notifications_screen.dart';

class UserFeedbackScreen extends StatefulWidget {
  const UserFeedbackScreen({super.key});
  @override
  State<UserFeedbackScreen> createState() => _UserFeedbackScreenState();
}
class _UserFeedbackScreenState extends State<UserFeedbackScreen> {
  int rating = 3;
  final List<String> categories = [
    "App Experience",
    "Destinations",
    "Itinerary Planning",
    "Other",
  ];
  String? selectedCategory;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5EFE4), 
      appBar: AppBar(
        leading: const BackButton(color: Colors.black),
        backgroundColor: const Color(0xffF5EFE4),
        elevation: 0,
        centerTitle: true,
        title: Image.asset("images/logo.png", height: 55),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Text(
              "User Feedback",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xff1A2B49),
              ),
            ),
            const SizedBox(height: 30),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(50),
              decoration: BoxDecoration(
                color: const Color(0xffF5EFE4),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xff1A2B49)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    "We value your opinion",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Color(0xff1A2B49),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "How would you rate overall, experience?",
                    style: TextStyle(color: Color(0xff1A2B49), fontSize: 14),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: List.generate(5, (i) {
                      return IconButton(
                        onPressed: () {
                          setState(() => rating = i + 1);
                        },
                        icon: Icon(
                          Icons.star,
                          size: 30,
                          color: i < rating
                              ? const Color(0xff1A2B49)
                              : const Color(0xffD8D8D8),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    alignment: Alignment.centerLeft,
                    child: const Text(
                      "Category",
                      style: TextStyle(color: Color(0xff1A2B49)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xff1A2B49)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: selectedCategory,
                      underline: const SizedBox(),
                      iconEnabledColor: const Color(0xff1A2B49),
                      hint: const Text(
                        "Select",
                        style: TextStyle(color: Color(0xff1A2B49)),
                      ),
                      dropdownColor: const Color(0xffffffff),
                      style: const TextStyle(color: Color(0xff1A2B49)),
                      items: categories
                          .map(
                            (e) => DropdownMenuItem(
                              value: e,
                              child: Text(
                                e,
                                style: const TextStyle(
                                  color: Color(0xff1A2B49),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => selectedCategory = v),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Container(
                    height: 120,
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xff1A2B49)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TextField(
                      maxLines: null,
                      decoration: const InputDecoration(
                        filled: true,
                        fillColor: Color(0xffF5EFE4),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.all(12),
                        hintText: "Write your feedback",
                        hintStyle: TextStyle(color: Color(0xff1A2B49)),
                      ),
                      style: const TextStyle(color: Color(0xff1A2B49)),
                    ),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff1A2B49),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      onPressed: () {},
                      child: const Text(
                        "Submit",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
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
    );
  }
}
