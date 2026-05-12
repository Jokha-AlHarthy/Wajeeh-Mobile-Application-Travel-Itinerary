/// Result of attempting to save a PDF through the system UI.
enum PdfSaveOutcome {
  /// File was written to a path the user confirmed (save dialog / SAF).
  savedToChosenPath,

  /// User dismissed the save dialog without saving.
  cancelledByUser,

  /// A share sheet was shown so the user can pick an app (Files, Drive, etc.).
  presentedShareSheet,
}
