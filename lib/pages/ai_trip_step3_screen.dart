import 'package:flutter/material.dart';
import 'ai_trip_step4_screen.dart';
import 'notifications_screen.dart';

class AiTripStep3Screen extends StatefulWidget {
  const AiTripStep3Screen({super.key});
  @override
  State<AiTripStep3Screen> createState() => _AiTripStep3ScreenState();
}
class _AiTripStep3ScreenState extends State<AiTripStep3Screen> {
  DateTime focusedDay = DateTime(2025, 5, 1);
  DateTime? startDate;
  DateTime? endDate;
  void onDateSelected(DateTime date) {
    setState(() {
      if (startDate == null || (startDate != null && endDate != null)) {
        startDate = date;
        endDate = null;
      } else {
        if (date.isBefore(startDate!)) {
          endDate = startDate;
          startDate = date;
        } else {
          endDate = date;
        }
      }
    });
  }
  bool isInRange(DateTime day) {
    if (startDate == null || endDate == null) return false;
    return day.isAfter(startDate!) && day.isBefore(endDate!);
  }
  bool isSelected(DateTime day) {
    return (startDate != null && day == startDate) ||
        (endDate != null && day == endDate);
  }
  String get rangeText {
    if (startDate == null || endDate == null) return "";
    return "${startDate!.day}–${endDate!.day} ${_monthName(startDate!.month)}, ${startDate!.year}";
  }
  String _monthName(int m) {
    const names = [
      "",
      "January",
      "February",
      "March",
      "April",
      "May",
      "June",
      "July",
      "August",
      "September",
      "October",
      "November",
      "December",
    ];
    return names[m];
  }
  int daysInMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0).day;
  }
  @override
  Widget build(BuildContext context) {
    int totalDays = daysInMonth(focusedDay);
    return Scaffold(
      backgroundColor: const Color(0xffF5EFE4),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        centerTitle: true,
        title: const Text(
          "Step 3",
          style: TextStyle(
            color: Color(0xff1A2B49),
            fontSize: 20,
            fontWeight: FontWeight.bold,
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
              "When will this journey start?",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xff1A2B49),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Determine when and how long you will travel\nfor proper planning",
              style: TextStyle(fontSize: 16, color: Color(0xff1A2B49)),
            ),
            const SizedBox(height: 20),
            const Text(
              "Select Date",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xff1A2B49),
              ),
            ),
            const SizedBox(height: 8),
            if (rangeText.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6, bottom: 10),
                child: Text(
                  rangeText,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.orange,
                  ),
                ),
              ),
            Expanded(
              child: GestureDetector(
                onHorizontalDragEnd: (details) {
                  if (details.primaryVelocity! < 0) {
                    setState(() {
                      focusedDay = DateTime(
                        focusedDay.year,
                        focusedDay.month + 1,
                        1,
                      );
                    });
                  } else if (details.primaryVelocity! > 0) {
                    setState(() {
                      focusedDay = DateTime(
                        focusedDay.year,
                        focusedDay.month - 1,
                        1,
                      );
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.black12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.chevron_left,
                              color: Colors.orange,
                            ),
                            onPressed: () {
                              setState(() {
                                focusedDay = DateTime(
                                  focusedDay.year,
                                  focusedDay.month - 1,
                                  1,
                                );
                              });
                            },
                          ),
                          Text(
                            "${_monthName(focusedDay.month)} ${focusedDay.year}",
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.chevron_right,
                              color: Colors.orange,
                            ),
                            onPressed: () {
                              setState(() {
                                focusedDay = DateTime(
                                  focusedDay.year,
                                  focusedDay.month + 1,
                                  1,
                                );
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          Text("Sun"),
                          Text("Mon"),
                          Text("Tue"),
                          Text("Wed"),
                          Text("Thu"),
                          Text("Fri"),
                          Text("Sat"),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: GridView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: totalDays,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 7,
                                childAspectRatio: 1.2,
                              ),
                          itemBuilder: (context, index) {
                            final day = index + 1;
                            final date = DateTime(
                              focusedDay.year,
                              focusedDay.month,
                              day,
                            );
                            final selected = isSelected(date);
                            final inRange = isInRange(date);
                            Color bg = Colors.transparent;
                            if (inRange) bg = Colors.orange.shade100;
                            if (selected) bg = Colors.orange.shade300;
                            return GestureDetector(
                              onTap: () => onDateSelected(date),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: bg,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  "$day",
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
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
            ),
            const SizedBox(height: 200),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AiTripStep4Screen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff1A2B49),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text(
                  "Next Step",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
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
