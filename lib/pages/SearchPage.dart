import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;

class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = fb_auth.FirebaseAuth.instance.currentUser;

    const darkBlue = Color(0xFF0C1C3D);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Image.asset("images/logo.png", height: 40),
        actions: [
          GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, '/notifications');
            },
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(
                    Icons.notifications,
                    size: 28,
                    color: darkBlue,
                  ),
                  Positioned(
                    right: -2,
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
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: user != null
            ? FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .snapshots()
            : null,
        builder: (context, snapshot) {
          final userName = snapshot.data?.data()?['username'] as String?;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                const TextField(
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: "Search",
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  "Last Search",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _chip("Qurum Beach"),
                    _chip("Nizwa Fort"),
                    _chip("Wadi Shab"),
                    _chip("Ras Al Jinz"),
                    _chip("Salalah Waterfalls"),
                  ],
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text(
                      "Recently Viewed",
                      style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    Text("View All", style: TextStyle(fontSize: 14)),
                  ],
                ),
                const SizedBox(height: 16),
                _placeRow(
                  image:
                  "https://a.travel-assets.com/findyours-php/viewfinder/images/res70/59000/59871-Muscat.jpg",
                  title: "Matrah",
                  subtitle: "• 15 km",
                ),
                const SizedBox(height: 16),
                _placeRow(
                  image:
                  "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQAbi543pHNd22NA8sECorYJtOlrUMSC7ARJw&s",
                  title: "Qurayyat",
                  subtitle: " • 2.1 km",
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text(
                      "Popular Destinations",
                      style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    Text("View All", style: TextStyle(fontSize: 14)),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 180,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _popularCard(
                        "Matrah",
                        "https://a.travel-assets.com/findyours-php/viewfinder/images/res70/59000/59871-Muscat.jpg",
                      ),
                      _popularCard(
                        "Qurayyat",
                        "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQAbi543pHNd22NA8sECorYJtOlrUMSC7ARJw&s",
                      ),
                      _popularCard(
                        "Al-Mudhaibi",
                        "https://nsg.gov.om/images/%D8%A7%D9%84%D9%85%D8%B6%D9%8A%D8%A8%D9%8A/gwraya.jpg",
                      ),
                    ],
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }

  static Widget _chip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: const TextStyle(color: Colors.black)),
    );
  }

  static Widget _placeRow({
    required String image,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Image.network(
            image,
            width: 70,
            height: 70,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
            ],
          ),
        ),
        const Icon(Icons.arrow_forward_ios, size: 16),
      ],
    );
  }

  static Widget _popularCard(String title, String image) {
    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        image: DecorationImage(
          image: NetworkImage(image),
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Colors.white70,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.favorite_border, size: 18),
            ),
          ),
          Positioned(
            bottom: 12,
            left: 12,
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(color: Colors.black54, blurRadius: 6),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
