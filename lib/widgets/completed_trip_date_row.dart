import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../utils/saved_trip_extensions.dart';

/// Single line: small location icon + formatted start–end dates (completed trips).
class CompletedTripDateRow extends StatelessWidget {
  const CompletedTripDateRow({
    super.key,
    required this.trip,
    this.textStyle,
    this.iconSize = 15,
  });

  final Map<String, dynamic> trip;
  final TextStyle? textStyle;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final start = trip.tripStartDate;
    final end = trip.tripEndDate;
    final lang = Localizations.localeOf(context).languageCode;
    final fmt = DateFormat('d MMM y', lang == 'ar' ? 'ar' : 'en');

    String text;
    if (start != null && end != null) {
      final a = DateTime(start.year, start.month, start.day);
      final b = DateTime(end.year, end.month, end.day);
      text = '${fmt.format(a)} - ${fmt.format(b)}';
    } else {
      text = trip['dateText']?.toString() ?? '';
    }

    if (text.isEmpty) return const SizedBox.shrink();

    final baseStyle = textStyle ??
        theme.textTheme.bodyMedium?.copyWith(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
        );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          Icons.location_on_outlined,
          size: iconSize,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: baseStyle,
          ),
        ),
      ],
    );
  }
}
