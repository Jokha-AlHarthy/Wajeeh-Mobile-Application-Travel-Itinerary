import 'dart:io';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:share_plus/share_plus.dart';

import 'pdf_save_outcome.dart';

Future<PdfSaveOutcome> savePdfBytesImpl(String baseFileName, Uint8List bytes) async {
  final safe = _safeBaseName(baseFileName);
  final suggested = '$safe.pdf';
  final group = XTypeGroup(
    label: 'PDF',
    extensions: const <String>['pdf'],
    mimeTypes: const <String>['application/pdf'],
  );

  try {
    final FileSaveLocation? location = await getSaveLocation(
      acceptedTypeGroups: <XTypeGroup>[group],
      suggestedName: suggested,
    );
    if (location == null) {
      return PdfSaveOutcome.cancelledByUser;
    }
    await File(location.path).writeAsBytes(bytes, flush: true);
    return PdfSaveOutcome.savedToChosenPath;
  } catch (_) {
    await Share.shareXFiles(
      <XFile>[
        XFile.fromData(
          bytes,
          name: suggested,
          mimeType: 'application/pdf',
        ),
      ],
    );
    return PdfSaveOutcome.presentedShareSheet;
  }
}

String _safeBaseName(String raw) {
  var s = raw.trim().replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
  if (s.isEmpty) s = 'document';
  if (s.length > 120) s = s.substring(0, 120);
  return s;
}
