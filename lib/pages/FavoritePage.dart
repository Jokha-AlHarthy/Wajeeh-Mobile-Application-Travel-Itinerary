import 'package:flutter/material.dart';
import 'package:wajeeh/widgets/app_footer.dart';

class FavoritePage extends StatelessWidget {
  const FavoritePage({super.key});

  static const cream = Color(0xffF7F1E8);
  static const darkBlue = Color(0xFF0C1C3D);

  @override
  Widget build(BuildContext context) {
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
                  const SizedBox(width: 40), // to balance layout

                  // Center Logo
                  Image.asset("images/logo.png", height: 55),

                  // Notification Button
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
                          color: Color(0xFF0C1C3D),
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
                ],
              ),

              const SizedBox(height: 10),

              // -------- TITLE -------- //
              const Center(
                child: Text(
                  "My Favorite",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: darkBlue,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // -------- SEARCH BOX -------- //
              Row(
                children: [
                  Expanded(
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

              // -------- CATEGORY CHIPS -------- //
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: const [
                    _Chip(
                      label: "History",
                      icon: Icons.history_edu,
                      selected: true,
                    ),
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

              // -------- FAVORITE CARDS -------- //
              _FavoriteCard(
                title: "Burj Khalifa",
                country: "United Arab Emirates",
                image:
                "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTA1NFo2irXJ0RLEU8AhJY0Xuj9ZK_Fb_1ASw&s",
                price: "OMR 19-20 / Person",
              ),
              const SizedBox(height: 16),
              _FavoriteCard(
                title: "Sultan Qaboos Grand",
                country: "Al Ghubrah, Muscat",
                image:
                "https://worldarchitecture.org/cdnimgfiles/extuploadc/coverpic-1-.jpg",
                price: "OMR 5-10 / Person",
              ),
            ],
          ),
        ),
      ),

      // -------- FOOTER -------- //
      bottomNavigationBar: const AppFooter(currentIndex: 3),
    );
  }
}

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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFF0C1C3D) : Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon,
              size: 16,
              color: selected ? Colors.white : const Color(0xFF0C1C3D)),
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



class _FavoriteCard extends StatelessWidget {
  final String title, country, image, price;

  const _FavoriteCard({
    required this.title,
    required this.country,
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
          // overlay darkness
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              color: Colors.black.withOpacity(0.25),
            ),
          ),

          // TOP ROW: country + heart
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const Icon(Icons.location_on,
                    color: Colors.white, size: 16),
                const SizedBox(width: 4),
                Text(
                  country,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 13),
                ),
                const Spacer(),
                const Icon(Icons.favorite,
                    color: Colors.white), // filled heart
              ],
            ),
          ),

          // BOTTOM WHITE INFO CARD
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

          // ARROW BUTTON (same as HomePage)
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

