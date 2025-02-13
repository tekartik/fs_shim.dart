import 'dart:io';

import 'package:fs_shim/src/platform/platform.dart';

/// Io context
final PlatformContextIo platformContextIo =
    PlatformContextIo()
      ..isIoLinux = Platform.isLinux
      ..isIoMacOS = Platform.isMacOS
      ..isIoWindows = Platform.isWindows;

/// Browser context
PlatformContextBrowser get platformContextBrowser =>
    throw UnsupportedError('platformContextWeb on io');

/// Common platform context
PlatformContext get platformContext => platformContextIo;
