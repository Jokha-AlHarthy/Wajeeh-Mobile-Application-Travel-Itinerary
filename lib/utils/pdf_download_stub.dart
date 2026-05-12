import 'dart:typed_data';

import 'pdf_save_outcome.dart';

Future<PdfSaveOutcome> savePdfBytesImpl(String baseFileName, Uint8List bytes) async {
  throw UnsupportedError('PDF save is not supported on this platform.');
}
