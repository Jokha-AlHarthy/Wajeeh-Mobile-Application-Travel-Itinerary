// Browser PDF download via blob URL (dart:html; use package:web when migrating).
// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter

import 'dart:html' as html;
import 'dart:typed_data';

import 'pdf_save_outcome.dart';

Future<PdfSaveOutcome> savePdfBytesImpl(String baseFileName, Uint8List bytes) async {
  final safe = _safeBaseName(baseFileName);
  final blob = html.Blob([bytes], 'application/pdf');
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', '$safe.pdf')
    ..style.display = 'none';
  html.document.body!.children.add(anchor);
  anchor.click();
  anchor.remove();
  html.Url.revokeObjectUrl(url);
  return PdfSaveOutcome.savedToChosenPath;
}

String _safeBaseName(String raw) {
  var s = raw.trim().replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
  if (s.isEmpty) s = 'document';
  if (s.length > 120) s = s.substring(0, 120);
  return s;
}
