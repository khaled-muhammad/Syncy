import 'dart:io';

import 'package:flutter/foundation.dart';

/// Whether the app is running on a desktop operating system.
///
/// Desktop builds differ from mobile in ways that cut across the whole app:
/// the playback backend, the media library model, window chrome, and layout.
/// Routing every one of those decisions through a single getter keeps the
/// mobile code paths untouched and makes the desktop surface easy to audit.
bool get isDesktop =>
    !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

/// Whether the app is running on Windows.
bool get isWindows => !kIsWeb && Platform.isWindows;

/// Whether the app is running on a touch-first mobile operating system.
bool get isMobile => !kIsWeb && (Platform.isAndroid || Platform.isIOS);
