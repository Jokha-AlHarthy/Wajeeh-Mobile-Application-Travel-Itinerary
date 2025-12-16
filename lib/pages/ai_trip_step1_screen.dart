import 'package:flutter/material.dart';
import 'ai_trip_step2_screen.dart';
import 'notifications_screen.dart';

class AiTripStep1Screen extends StatefulWidget {
  const AiTripStep1Screen({super.key});
  @override
  State<AiTripStep1Screen> createState() => _AiTripStep1ScreenState();
}

class _AiTripStep1ScreenState extends State<AiTripStep1Screen> {
  String selectedCountry = "Oman";
  final List<Map<String, String>> countries = [
    {"name": "Oman", "flag": "images/oman.png"},
    {"name": "Qatar", "flag": "images/qatar.png"},
    {"name": "Bahrain", "flag": "images/bahrain.png"},
    {"name": "Kuwait", "flag": "images/kuwait.png"},
    {"name": "Saudi Arabia", "flag": "images/saudi.png"},
    {"name": "United Arab Emirates", "flag": "images/uae.png"},
  ];
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
          "Step 1",
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
              "Where are you going?",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xff1A2B49),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              "Let’s explore various countries in the world",
              style: TextStyle(fontSize: 16, color: Color(0xff1A2B49)),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.separated(
                itemCount: countries.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 40),
                itemBuilder: (context, index) {
                  final country = countries[index];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 0),
                    leading: Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.grey.shade300,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color.fromRGBO(0, 0, 0, 0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: FittedBox(
                          fit: BoxFit.contain, // ensures image fully fits
                          child: Image.asset(country["flag"]!),
                        ),
                      ),
                    ),
                    title: Text(
                      country["name"]!,
                      style: const TextStyle(
                        color: Color(0xff1A2B49),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    trailing: RadioButton(
                      selected: selectedCountry == country["name"],
                      onPressed: () {
                        setState(() {
                          selectedCountry = country["name"]!;
                        });
                      },
                    ),
                  );
                },
              ),
            ),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AiTripStep2Screen(),
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
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
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

class RadioButton extends StatelessWidget {
  final bool selected;
  final VoidCallback onPressed;
  const RadioButton({
    super.key,
    required this.selected,
    required this.onPressed,
  });
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? const Color(0xff0C1B33) : Colors.grey,
            width: 2,
          ),
        ),
        child: selected
            ? const Center(
                child: CircleAvatar(
                  radius: 7,
                  backgroundColor: Color(0xff1A2B49),
                ),
              )
            : null,
      ),
    );
  }
}
