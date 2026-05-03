import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';

/// Simple, reliable-ish internet check used at app launch.
///
/// We combine:
/// - device network connectivity (wifi/mobile/ethernet)
/// - a short DNS lookup to verify real internet reachability
///
/// NOTE: This is intentionally lightweight and dependency-free beyond
/// `connectivity_plus` (already used widely in Flutter apps).
class InternetConnectivity {
  InternetConnectivity._();

  static Future<bool> hasInternet({
    Duration timeout = const Duration(seconds: 3),
  }) async {
    try {
      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity.contains(ConnectivityResult.none)) return false;

      // DNS check. `example.com` is stable and lightweight.
      final lookup = InternetAddress.lookup('example.com')
          .timeout(timeout);
      final result = await lookup;
      return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}

