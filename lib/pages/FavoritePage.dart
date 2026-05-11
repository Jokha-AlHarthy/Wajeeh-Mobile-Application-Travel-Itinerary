import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wajeeh/widgets/app_footer.dart';
import 'package:wajeeh/widgets/place_list_card.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../localization/app_localizations.dart';
import '../providers/travel_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FavoritePage extends StatelessWidget {
  const FavoritePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor = theme.colorScheme.primary;
    final cardColor = theme.cardTheme.color ?? theme.colorScheme.surface;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Consumer<TravelProvider>(
          builder: (context, travel, _) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(width: 40),
                      Image.asset("images/logo.png", height: 55),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(context, '/notifications');
                        },
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Icon(
                              Icons.notifications,
                              size: 28,
                              color: accentColor,
                            ),
                            PositionedDirectional(
                              end: -1,
                              top: -2,
                              child: StreamBuilder<QuerySnapshot>(
                                stream: FirebaseFirestore.instance
                                    .collection("notifications")
                                    .where(
                                  "userId",
                                  isEqualTo:
                                  firebase_auth.FirebaseAuth.instance.currentUser?.uid,
                                )
                                    .where("isRead", isEqualTo: false)
                                    .snapshots(),
                                builder: (context, snapshot) {

                                  if (!snapshot.hasData ||
                                      snapshot.data!.docs.isEmpty) {
                                    return const SizedBox();
                                  }

                                  final count = snapshot.data!.docs.length;

                                  return Container(
                                    padding: const EdgeInsets.all(3),
                                    constraints: const BoxConstraints(
                                      minWidth: 18,
                                      minHeight: 18,
                                    ),
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      count.toString(),
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: Text(
                      context.tr('my_favorite'),
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (travel.favoritePlaces.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 48),
                      child: Center(
                        child: Text(
                          context.tr('no_favorite_places'),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: theme.textTheme.bodySmall?.color ??
                                Colors.grey,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    )
                  else
                    Column(
                      children: [
                        for (int i = 0; i < travel.favoritePlaces.length; i++) ...[
                          PlaceListCard(
                            place: travel.favoritePlaces[i],
                            accentColor: accentColor,
                            cardColor: cardColor,
                          ),
                          if (i < travel.favoritePlaces.length - 1)
                            const SizedBox(height: 16),
                        ],
                      ],
                    ),
                ],
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: const AppFooter(currentIndex: 3),
    );
  }
}
