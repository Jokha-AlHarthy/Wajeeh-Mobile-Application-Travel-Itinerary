import 'package:flutter/material.dart';
import 'package:wajeeh/widgets/app_footer.dart';

class EditLocationScreen extends StatefulWidget {
  const EditLocationScreen({super.key});

  @override
  State<EditLocationScreen> createState() => _EditLocationScreenState();
}

class _EditLocationScreenState extends State<EditLocationScreen> {
  final TextEditingController searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff7f1e8),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Back button + logo
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  "images/logo.png",
                  height: 95,
                ),
              ],
            ),


            const SizedBox(height: 8),

            const Text(
              "Edit your location",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0C1C3D),
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              "Choose your new location and let Wajeeh guide your next journey.",
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF0C1C3D),
              ),
            ),

            const SizedBox(height: 25),

            // Search box
            TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: "Search location",
                prefixIcon: const Icon(Icons.search, color: Color(0xFF0C1C3D)),
                filled: true,
                fillColor: Colors.white,

                // Border when NOT focused
                enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(
                    color: Color(0xFF0C1C3D), // 🔵 Your custom border color
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),

                // Border when focused
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(
                    color: Color(0xFF0C1C3D), // 🔵 Same color but nicer focus
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),

                // Optional: remove default grey border
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),


            const SizedBox(height: 15),

            // Set location on map button
            Center(
              child: SizedBox(
                width: 250,
                height: 50,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.location_on_outlined, color: Color(0xFF0C1C3D)),
                  label: const Text(
                    "Set Location on Map",
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF0C1C3D),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF0C1C3D)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {

                  },
                ),
              ),
            ),

            const SizedBox(height: 25),

            const Text(
              "Current Location",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0C1C3D),
              ),
            ),

            const SizedBox(height: 10),

            // Map image preview
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                "images/location.png",
                fit: BoxFit.cover,
                height: 220,
                width: double.infinity,
              ),
            ),

            const SizedBox(height: 30),

            // Use current location button
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, "/home");
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0C1C3D),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  "Update my current Location",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
      bottomNavigationBar: const AppFooter(currentIndex: 2),
    );
  }
}
