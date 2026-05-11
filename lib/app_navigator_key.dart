import 'package:flutter/material.dart';

/// Used for overlays (e.g. AI chat FAB) that live in [MaterialApp.builder] **beside**
/// the [Navigator] subtree, so their [BuildContext] does not include a [Navigator]
/// ancestor. [showModalBottomSheet] must be called with a context from this key.
final GlobalKey<NavigatorState> wajeehRootNavigatorKey = GlobalKey<NavigatorState>();
