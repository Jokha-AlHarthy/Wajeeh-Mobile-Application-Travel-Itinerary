import 'package:flutter/material.dart';

class RateScreen extends StatefulWidget {
  final String placeTitle;
  final String country;
  final double rating;
  final String image;

  const RateScreen({
    super.key,
    required this.placeTitle,
    required this.country,
    required this.rating,
    required this.image,
  });

  @override
  State<RateScreen> createState() => _RateScreenState();
}

class _RateScreenState extends State<RateScreen> {
  int selectedStars = 4;
  final TextEditingController reviewController = TextEditingController(
      text:
      "This was a very stressful experience,\nI will come again next year to this place");

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: 0.3),
      body: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Stack(
          children: [
            Container(color: Colors.transparent),

            // -------------------- Bottom Sheet --------------------
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 0),
                decoration: const BoxDecoration(
                  color: Color(0xffF5EFE4),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                height: MediaQuery.of(context).size.height * 0.65,
                child: Column(
                  children: [
                    // Drag handle
                    Container(
                      width: 50,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),

                    // -------------------- Place Image Full Width with Overlay Info --------------------
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.asset(
                            widget.image,
                            width: double.infinity,
                            height: 250,
                            fit: BoxFit.cover,
                          ),
                        ),
                        // Gradient overlay for readability
                        Container(
                          width: double.infinity,
                          height: 250,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.5),
                              ],
                            ),
                          ),
                        ),
                        // Place info overlay
                        Positioned(
                          left: 12,
                          bottom: 12,
                          right: 12,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.placeTitle,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.location_on_outlined,
                                      size: 14, color: Colors.white70),
                                  const SizedBox(width: 4),
                                  Text(
                                    widget.country,
                                    style: const TextStyle(
                                        fontSize: 13, color: Colors.white70),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.star,
                                      size: 14, color: Colors.amber),
                                  Text(
                                    widget.rating.toString(),
                                    style: const TextStyle(
                                        fontSize: 13, color: Colors.white),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // -------------------- Star Rating --------------------
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        bool filled = index < selectedStars;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedStars = index + 1;
                            });
                          },
                          child: Icon(
                            filled ? Icons.star : Icons.star_border,
                            color: const Color(0xff1A2B49),
                            size: 38,
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 5),

                    // -------------------- Detail Review Label --------------------
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Detail Review",
                        style: TextStyle(
                          color: Color(0xff9A9A9A),
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // -------------------- Review TextField --------------------
                    Container(
                      width: 390, // reduced width
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xffF5EFE4),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xff1A2B49), width: 1.4),
                      ),
                      child: TextField(
                        controller: reviewController,
                        maxLines: 5,
                        style: const TextStyle(
                          color: Color(0xff1A2B49),
                          fontSize: 15,
                        ),
                        decoration: const InputDecoration(border: InputBorder.none),
                      ),
                    ),
                    const SizedBox(height: 25),


                    // -------------------- Submit Button --------------------
                    Center(
                      child: SizedBox(
                        width: 260,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xff1A2B49),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text(
                            "Submit Review",
                            style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: Colors.white),
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
      ),
    );
  }
}
