import 'dart:convert';

import 'package:flutter/material.dart';

bool isHttpImageUrl(String? url) {
  if (url == null || url.isEmpty) return false;
  final u = url.trim().toLowerCase();
  return u.startsWith('http://') || u.startsWith('https://');
}

ImageProvider resolveProfileImageProvider({
  String? photoUrl,
  String? profilePhotoBase64,
  String defaultAsset = 'images/defaultUserProfile.png',
}) {
  final b64 = profilePhotoBase64?.trim();
  if (b64 != null && b64.isNotEmpty) {
    try {
      final bytes = base64Decode(b64);
      if (bytes.isNotEmpty) return MemoryImage(bytes);
    } catch (_) {}
  }

  if (isHttpImageUrl(photoUrl)) {
    return NetworkImage(photoUrl!.trim());
  }

  return AssetImage(defaultAsset);
}

ImageProvider resolveCoverImageProvider({
  String? coverUrl,
  String? coverPhotoBase64,
  String defaultAsset = 'images/defaultCover.png',
}) {
  final b64 = coverPhotoBase64?.trim();
  if (b64 != null && b64.isNotEmpty) {
    try {
      final bytes = base64Decode(b64);
      if (bytes.isNotEmpty) return MemoryImage(bytes);
    } catch (_) {}
  }

  if (isHttpImageUrl(coverUrl)) {
    return NetworkImage(coverUrl!.trim());
  }

  return AssetImage(defaultAsset);
}

bool hasCustomProfileImage({
  String? photoUrl,
  String? profilePhotoBase64,
}) {
  final b64 = profilePhotoBase64?.trim();
  if (b64 != null && b64.isNotEmpty) return true;
  return isHttpImageUrl(photoUrl);
}

bool hasCustomCoverImage({
  String? coverUrl,
  String? coverPhotoBase64,
}) {
  final b64 = coverPhotoBase64?.trim();
  if (b64 != null && b64.isNotEmpty) return true;
  return isHttpImageUrl(coverUrl);
}
