import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'package:wajeeh/widgets/app_footer.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  double priceValue = 50;

  final List<String> filterOptions = [
    "Hotels & Stays",
    "Food & Restaurants",
    "Transportation",
    "Culture & Heritage",
    "Shopping & Souvenirs",
  ];

  List<String> selectedFilters = [];

  void toggleFilter(String label) {
    setState(() {
      selectedFilters.contains(label)
          ? selectedFilters.remove(label)
          : selectedFilters.add(label);
    });
  }

  void showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
          child: StatefulBuilder(
            builder: (context, setSheetState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 60,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  const Center(
                    child: Text(
                      "Filter Service",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xff1A2B49),
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),

                  const Text(
                    "Locations",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff1A2B49),
                    ),
                  ),

                  const SizedBox(height: 10),

                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text(
                          "Dubai, United Arab Emirates",
                          style: TextStyle(color: Colors.black87, fontSize: 15),
                        ),
                        Icon(Icons.location_on_outlined,
                            color: Color(0xff1A2B49)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

                  const Text(
                    "Popular Filters",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff1A2B49),
                    ),
                  ),

                  const SizedBox(height: 12),

                  Wrap(
                    spacing: 10,
                    runSpacing: 12,
                    children: filterOptions.map((label) {
                      final isSelected = selectedFilters.contains(label);
                      return GestureDetector(
                        onTap: () {
                          setState(() => toggleFilter(label));
                          setSheetState(() {});
                        },
                        child: Container(
                          padding:
                          const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xff1A2B49)
                                : Colors.white,
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xff1A2B49)
                                  : Colors.grey.shade400,
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            label,
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : const Color(0xff1A2B49),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 30),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Price Range",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xff1A2B49),
                        ),
                      ),
                      Text(
                        "OMR ${priceValue.toInt()}",
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xff1A2B49),
                        ),
                      ),
                    ],
                  ),

                  Slider(
                    value: priceValue,
                    min: 0,
                    max: 200,
                    activeColor: const Color(0xff1A2B49),
                    inactiveColor: Colors.grey.shade300,
                    onChanged: (val) {
                      setSheetState(() => priceValue = val);
                      setState(() {});
                    },
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff1A2B49),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        "Apply Filter",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),
                ],
              );
            },
          ),
        );
      },
    );
  }

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
                        const Icon(Icons.notifications, size: 28, color: darkBlue),
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

              Center(
                child: Column(
                  children: [
                    Text(
                      "Hi, $name",
                      style:
                      const TextStyle(fontSize: 18, color: Colors.black54),
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: Colors.grey),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        "Search location",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                    GestureDetector(
                      onTap: showFilterSheet,
                      child: const Icon(Icons.tune, color: darkBlue),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

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
      bottomNavigationBar: const AppFooter(currentIndex: 0),
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
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              color: Colors.black.withOpacity(0.25),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const Icon(Icons.location_on, color: Colors.white, size: 16),
                const SizedBox(width: 4),
                Text(
                  country,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.star, color: Colors.amber, size: 16),
                Text(
                  rating,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
                const Spacer(),
                const Icon(Icons.favorite_border, color: Colors.white),
              ],
            ),
          ),

          Positioned(
            left: 14,
            right: 80,
            bottom: 14,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
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

                  Row(
                    children: [
                      const Text(
                        "Start from ",
                        style: TextStyle(
                          color: Colors.black54,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        price.split("/").first.trim(),
                        style: const TextStyle(
                          color: Color(0xFFF89C1B),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        " / ${price.split("/").last.trim()}",
                        style: const TextStyle(
                          color: Color(0xFFF2B86C),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          Positioned(
            right: -5,
            bottom: -7,
            child: Container(
              width: 70,
              height: 70,
              decoration: const BoxDecoration(
                color: cream,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Container(
                  width: 55,
                  height: 55,
                  decoration: const BoxDecoration(
                    color: darkBlue,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.north_east,
                    color: Colors.white,
                    size: 25,
                    shadows: [
                      Shadow(
                        offset: Offset(0, 0),
                        blurRadius: 3,
                        color: Colors.white,
                      ),
                    ],
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
