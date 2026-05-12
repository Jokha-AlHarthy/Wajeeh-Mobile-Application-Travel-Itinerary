import 'dart:typed_data';

import 'pdf_download_stub.dart'
    if (dart.library.html) 'pdf_download_web.dart'
    if (dart.library.io) 'pdf_download_io.dart';
import 'pdf_save_outcome.dart';

export 'pdf_save_outcome.dart';

/// Saves [bytes] as a PDF using a system save dialog when available, otherwise
/// a share sheet (mobile) or browser download (web).
Future<PdfSaveOutcome> savePdfToDevice(String baseFileName, Uint8List bytes) {
  return savePdfBytesImpl(baseFileName, bytes);
}
