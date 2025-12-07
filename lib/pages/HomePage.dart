import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'package:wajeeh/widgets/app_footer.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final name = Provider.of<AuthProvider>(context).fullName ?? "User";

    const cream = Color(0xffF7F1E8);
    const darkBlue = Color(0xFF0C1C3D);

    return Scaffold(
      backgroundColor: cream,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // -------- TOP BAR -------- //
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.amber,
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  Image.asset("images/logo.png", height: 40),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, '/notifications');
                    },
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

                ],
              ),

              const SizedBox(height: 20),

              // -------- GREETING -------- //
              Center(
                child: Column(
                  children: [
                    Text(
                      "Hi, $name",
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.black54,
                      ),
                    ),
                    const Text(
                      "Al Khuwair, Muscat",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: darkBlue,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // -------- SEARCH BOX -------- //
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        Navigator.pushNamed(context, '/search');
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.search, color: Colors.grey),
                            SizedBox(width: 8),
                            Text(
                              "Search location",
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.tune, color: darkBlue),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // -------- CATEGORY CHIPS (SCROLLABLE) -------- //
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: const [
                    _Chip(label: "History", icon: Icons.history_edu, selected: true),
                    SizedBox(width: 10),
                    _Chip(label: "Food", icon: Icons.restaurant),
                    SizedBox(width: 10),
                    _Chip(label: "Shopping", icon: Icons.shopping_bag_outlined),
                    SizedBox(width: 10),
                    _Chip(label: "Enter", icon: Icons.celebration),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // -------- CARDS -------- //
              _PlaceCard(
                title: "Burj Khalifa",
                country: "United Arab Emirates",
                rating: "4.0",
                image:
                "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTA1NFo2irXJ0RLEU8AhJY0Xuj9ZK_Fb_1ASw&s",
                price: "OMR 19-20 / Person",
              ),
              const SizedBox(height: 16),
              _PlaceCard(
                title: "Sultan Qaboos Grand",
                country: "Al Ghubrah, Muscat",
                rating: "4.5",
                image:
                "https://worldarchitecture.org/cdnimgfiles/extuploadc/coverpic-1-.jpg",
                price: "OMR 5-10 / Person",
              ),
            ],
          ),
        ),
      ),

      // =================== CUSTOM FOOTER =================== //
      bottomNavigationBar: const AppFooter(currentIndex: 0),
    );
  }
}

// ---------------- Small widgets ----------------

class _Chip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;

  const _Chip({
    required this.label,
    required this.icon,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFF0C1C3D) : Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: selected ? Colors.white : const Color(0xFF0C1C3D),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : const Color(0xFF0C1C3D),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaceCard extends StatelessWidget {
  final String title, country, rating, image, price;

  const _PlaceCard({
    required this.title,
    required this.country,
    required this.rating,
    required this.image,
    required this.price,
  });

  static const cream = Color(0xFFF7F1E8);

  @override
  Widget build(BuildContext context) {
    const darkBlue = Color(0xFF0C1C3D);

    return Container(
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        image: DecorationImage(
          image: NetworkImage(image),
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // dark overlay
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              color: Colors.black.withOpacity(0.25),
            ),
          ),

          // top row (country + rating + fav)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const Icon(Icons.location_on,
                    color: Colors.white, size: 16),
                const SizedBox(width: 4),
                Text(
                  country,
                  style:
                  const TextStyle(color: Colors.white, fontSize: 13),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.star,
                    color: Colors.amber, size: 16),
                Text(
                  rating,
                  style:
                  const TextStyle(color: Colors.white, fontSize: 13),
                ),
                const Spacer(),
                const Icon(Icons.favorite_border, color: Colors.white),
              ],
            ),
          ),

          // bottom info card
          Positioned(
            left: 14,
            right: 34,
            bottom: 14,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: darkBlue,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    price,
                    style: const TextStyle(
                      color: Color(0xFFF89C1B),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),


          Positioned(
            right: -23,
            bottom: -7,
            child: Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: cream,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: darkBlue,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.north_east,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
