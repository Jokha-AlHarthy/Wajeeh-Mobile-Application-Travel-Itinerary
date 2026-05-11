import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../pages/DisplayResultScreen.dart';
import '../providers/travel_provider.dart';
import '../services/itinerary_walkthrough.dart';

/// Home / Favorites list card: image, location, rating, favorite toggle, open detail.
class PlaceListCard extends StatelessWidget {
  final Map<String, dynamic> place;
  final Color accentColor;
  final Color cardColor;
  final GlobalKey? detailsButtonKey;

  const PlaceListCard({
    super.key,
    required this.place,
    required this.accentColor,
    required this.cardColor,
    this.detailsButtonKey,
  });

  @override
  Widget build(BuildContext context) {
    final travel = context.watch<TravelProvider>();
    final title = travel.placeName(place);
    final address = travel.placeAddress(place);
    final rating = place['rating']?.toString() ?? '0';
    final image = travel.firstPhotoUrl(place) ??
        "https://via.placeholder.com/400x220?text=No+Image";
    final priceLevel = travel.placePriceDisplayText(place);
    final subtext = travel.placeCardSubtext(place);
    final isFav = travel.isFavorite(place);

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: SizedBox(
        height: 220,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: Image.network(
                image,
                fit: BoxFit.cover,
                gaplessPlayback: true,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return Container(
                    color: Colors.grey.shade300,
                    child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                },
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.grey.shade300,
                  alignment: Alignment.center,
                  child: const Icon(Icons.image_not_supported,
                      color: Colors.white54, size: 40),
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.25),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const Icon(Icons.location_on, color: Colors.white, size: 16),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    address,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.star, color: Colors.amber, size: 16),
                Text(
                  rating,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () => travel.toggleFavorite(place),
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      isFav ? Icons.favorite : Icons.favorite_border,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          PositionedDirectional(
            start: 14,
            end: 80,
            bottom: 14,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 16,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (priceLevel.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      priceLevel,
                      style: TextStyle(
                        color: accentColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    subtext,
                    style: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.55),
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
          PositionedDirectional(
            end: -5,
            bottom: -7,
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: cardColor,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Container(
                  width: 55,
                  height: 55,
                  decoration: BoxDecoration(
                    color: accentColor,
                    shape: BoxShape.circle,
                  ),
                  child: GestureDetector(
                    key: detailsButtonKey,
                    onTap: () {
                      travel.addRecentlyViewed(place);
                      ItineraryWalkthroughController.instance.onOpenedPlaceDetails();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DisplayResultScreen(place: place),
                        ),
                      );
                    },
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
          ),
          ],
        ),
      ),
    );
  }
}
