import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Circular pin with order number for Google Maps markers.
Future<BitmapDescriptor> numberedRouteMarkerBitmap({
  required int order,
  required Color fill,
  int size = 96,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final cx = size / 2;
  final cy = size / 2;
  final r = size / 2 - 4;

  final shadow = Paint()
    ..color = Colors.black.withValues(alpha: 0.22)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
  canvas.drawCircle(Offset(cx, cy + 1.5), r, shadow);

  final fillPaint = Paint()..color = fill;
  canvas.drawCircle(Offset(cx, cy), r, fillPaint);

  final ring = Paint()
    ..color = Colors.white
    ..style = PaintingStyle.stroke
    ..strokeWidth = size * 0.045;
  canvas.drawCircle(Offset(cx, cy), r - ring.strokeWidth / 2, ring);

  final tp = TextPainter(
    text: TextSpan(
      text: '$order',
      style: TextStyle(
        color: Colors.white,
        fontSize: size * 0.42,
        fontWeight: FontWeight.w800,
        height: 1,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  tp.paint(canvas, Offset(cx - tp.width / 2, cy - tp.height / 2));

  final picture = recorder.endRecording();
  final image = await picture.toImage(size, size);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  if (bytes == null) {
    return BitmapDescriptor.defaultMarker;
  }
  final u8 = bytes.buffer.asUint8List();
  final dpr =
      ui.PlatformDispatcher.instance.implicitView?.devicePixelRatio ?? 2.0;
  return BitmapDescriptor.bytes(u8, imagePixelRatio: dpr);
}
