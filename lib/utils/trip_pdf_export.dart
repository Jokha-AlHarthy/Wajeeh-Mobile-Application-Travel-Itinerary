import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../localization/app_localizations.dart';
import '../providers/travel_provider.dart';
import 'ai_trip_plan_markdown_parser.dart';
import 'trip_detail_shared_text.dart';

bool _tripEndIsBeforeToday(Map<String, dynamic> trip) {
  final endStr = trip['endDate']?.toString();
  if (endStr == null || endStr.isEmpty) return false;
  final end = DateTime.tryParse(endStr);
  if (end == null) return false;
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final endOnly = DateTime(end.year, end.month, end.day);
  return endOnly.isBefore(today);
}

/// Single-line cells for the trip itinerary table.
class _TripPdfActivityLine {
  const _TripPdfActivityLine({
    required this.section,
    required this.category,
    required this.activity,
    required this.whenText,
    required this.price,
  });

  final String section;
  final String category;
  final String activity;
  final String whenText;
  final String price;
}

List<_TripPdfActivityLine> _collectTripPdfLines(
  BuildContext context,
  TravelProvider travel,
  Map<String, dynamic> trip,
) {
  final out = <_TripPdfActivityLine>[];
  final daysRaw = trip['days'];
  if (daysRaw is! List || daysRaw.isEmpty) {
    return out;
  }

  for (final raw in daysRaw) {
    if (raw is! Map) continue;
    final dayMap = Map<String, dynamic>.from(raw);
    final dn = dayMap['dayNumber'];
    final dayNumber = dn is int ? dn : int.tryParse(dn.toString()) ?? 0;
    final dateStr = dayMap['date']?.toString() ?? '';
    final placesRaw = dayMap['places'];
    final places = <Map<String, dynamic>>[];
    if (placesRaw is List) {
      for (final p in placesRaw) {
        if (p is Map<String, dynamic>) {
          places.add(p);
        } else if (p is Map) {
          places.add(Map<String, dynamic>.from(p));
        }
      }
    }

    final dayTitle =
        tripDetailDayTitle(context, dayNumber, dateStr, trip);

    if (tripDetailPlacesUseStructuredLayout(places)) {
      final ordered = List<Map<String, dynamic>>.from(places);
      ordered.sort(
        (a, b) => AiTripPlanMarkdownParser.slotOrderForCategoryKey(
              a['itineraryCategoryKey']?.toString(),
            )
            .compareTo(
              AiTripPlanMarkdownParser.slotOrderForCategoryKey(
                b['itineraryCategoryKey']?.toString(),
              ),
            ),
      );
      for (final place in ordered) {
        final row = tripItineraryRowText(
          context,
          travel,
          place,
          dateStr,
          dayNumber,
        );
        out.add(
          _TripPdfActivityLine(
            section: dayTitle,
            category: row.category,
            activity: row.activityTitle,
            whenText: row.subtitle,
            price: row.price,
          ),
        );
      }
      continue;
    }

    void addRowsForSection(String sectionLabel, List<Map<String, dynamic>> list) {
      for (final place in list) {
        final row = tripItineraryRowText(
          context,
          travel,
          place,
          dateStr,
          dayNumber,
        );
        out.add(
          _TripPdfActivityLine(
            section: sectionLabel.isEmpty ? dayTitle : '$dayTitle · $sectionLabel',
            category: row.category,
            activity: row.activityTitle,
            whenText: row.subtitle,
            price: row.price,
          ),
        );
      }
    }

    if (places.isEmpty) {
      continue;
    }

    final hotels = <Map<String, dynamic>>[];
    final timed = <Map<String, dynamic>>[];

    for (final place in places) {
      if (travel.placeIsHotelStayInTrip(place)) {
        hotels.add(place);
      } else {
        timed.add(place);
      }
    }

    timed.sort(
      (a, b) => tripDetailMinutesForSort(travel, a)
          .compareTo(tripDetailMinutesForSort(travel, b)),
    );

    if (hotels.isNotEmpty) {
      addRowsForSection(context.tr('hotel_stays_section'), hotels);
    }

    final morning = <Map<String, dynamic>>[];
    final afternoon = <Map<String, dynamic>>[];
    final evening = <Map<String, dynamic>>[];

    for (final place in timed) {
      final mins = travel.scheduledTimeMinutesFromTripPlace(place) ?? 12 * 60;
      final hour = mins ~/ 60;

      if (hour < 12) {
        morning.add(place);
      } else if (hour < 17) {
        afternoon.add(place);
      } else {
        evening.add(place);
      }
    }

    addRowsForSection(context.tr('morning'), morning);
    addRowsForSection(context.tr('afternoon'), afternoon);
    addRowsForSection(context.tr('evening'), evening);
  }

  return out;
}

Future<Uint8List> buildPlaceSharePdfBytes({
  required String title,
  required String description,
}) async {
  final font = await PdfGoogleFonts.notoSansRegular();
  final fontBold = await PdfGoogleFonts.notoSansBold();

  final doc = pw.Document();
  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      build: (c) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              title,
              style: pw.TextStyle(
                font: fontBold,
                fontSize: 18,
              ),
            ),
            pw.SizedBox(height: 14),
            pw.Text(
              description.trim().isEmpty ? '—' : description.trim(),
              style: pw.TextStyle(font: font, fontSize: 11),
            ),
          ],
        );
      },
    ),
  );
  return doc.save();
}

Future<Uint8List> buildTripDetailPdfBytes({
  required BuildContext context,
  required TravelProvider travel,
  required Map<String, dynamic> trip,
}) async {
  final loc = travel.historyLocationLinesForTrip(trip);
  final tripName = trip['tripName']?.toString().trim() ?? '';
  final title = tripName.isNotEmpty ? tripName : (loc['cities'] ?? '');
  final country = loc['countries'] ?? '';
  final dates = trip['dateText']?.toString() ?? '';
  final packageKeys = travel.packageIncludeKeysForTrip(trip);
  var packageLabel = packageKeys.map((k) => context.tr(k)).join(', ');
  if (packageLabel.isEmpty) {
    packageLabel = context.tr('package_includes_default');
  }
  final isPast = _tripEndIsBeforeToday(trip);
  final statusLabel =
      isPast ? context.tr('completed') : context.tr('on_going');

  final colDay = context.tr('pdf_column_day_section');
  final colCat = context.tr('pdf_column_category');
  final colAct = context.tr('pdf_column_activity');
  final colWhen = context.tr('pdf_column_when');
  final colPrice = context.tr('pdf_column_price');

  final lines = _collectTripPdfLines(context, travel, trip);

  final labelPackageIncludes = context.tr('package_includes');
  final labelDateBooking = context.tr('date_booking');
  final labelStatus = context.tr('status');
  final labelActivities = context.tr('activities');
  final emptyActivitiesMsg = context.tr('no_activities_scheduled');

  final font = await PdfGoogleFonts.notoSansRegular();
  final fontBold = await PdfGoogleFonts.notoSansBold();

  final doc = pw.Document();

  pw.Widget headerBlock() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(font: fontBold, fontSize: 16),
        ),
        pw.SizedBox(height: 6),
        pw.Text(
          '$labelPackageIncludes: $packageLabel',
          style: pw.TextStyle(font: font, fontSize: 10),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          '$labelDateBooking: $dates',
          style: pw.TextStyle(font: font, fontSize: 10),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          country,
          style: pw.TextStyle(font: font, fontSize: 10),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          '$labelStatus: $statusLabel',
          style: pw.TextStyle(font: font, fontSize: 10),
        ),
        pw.SizedBox(height: 12),
        pw.Text(
          labelActivities,
          style: pw.TextStyle(font: fontBold, fontSize: 13),
        ),
        pw.SizedBox(height: 8),
      ],
    );
  }

  pw.TableRow headerRow() {
    pw.Widget h(String s) => pw.Padding(
          padding: const pw.EdgeInsets.all(4),
          child: pw.Text(
            s,
            style: pw.TextStyle(font: fontBold, fontSize: 9),
          ),
        );
    return pw.TableRow(
      decoration: const pw.BoxDecoration(color: PdfColors.grey300),
      children: [
        h(colDay),
        h(colCat),
        h(colAct),
        h(colWhen),
        h(colPrice),
      ],
    );
  }

  pw.TableRow dataRow(_TripPdfActivityLine line) {
    pw.Widget c(String s) => pw.Padding(
          padding: const pw.EdgeInsets.all(4),
          child: pw.Text(
            s,
            style: pw.TextStyle(font: font, fontSize: 8),
          ),
        );
    return pw.TableRow(
      children: [
        c(line.section),
        c(line.category),
        c(line.activity),
        c(line.whenText),
        c(line.price),
      ],
    );
  }

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(36),
      build: (ctx) {
        final widgets = <pw.Widget>[
          headerBlock(),
        ];

        if (lines.isEmpty) {
          widgets.add(
            pw.Text(
              emptyActivitiesMsg,
              style: pw.TextStyle(font: font, fontSize: 10),
            ),
          );
        } else {
          widgets.add(
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey600, width: 0.5),
              columnWidths: {
                0: const pw.FlexColumnWidth(2.2),
                1: const pw.FlexColumnWidth(1.6),
                2: const pw.FlexColumnWidth(2.4),
                3: const pw.FlexColumnWidth(1.8),
                4: const pw.FlexColumnWidth(1.2),
              },
              children: [
                headerRow(),
                ...lines.map(dataRow),
              ],
            ),
          );
        }

        return widgets;
      },
    ),
  );

  return doc.save();
}
