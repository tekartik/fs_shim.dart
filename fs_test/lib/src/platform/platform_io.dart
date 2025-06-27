import 'dart:io';

import 'package:tekartik_fs_test/test_common.dart';

/// Io context
final PlatformContext platformContextIo = PlatformContextIo()
  ..isIoLinux = Platform.isLinux
  ..isIoMacOS = Platform.isMacOS
  ..isIoWindows = Platform.isWindows;

/// Browser context
PlatformContextBrowser get platformContextBrowser =>
    throw UnsupportedError('platformContextWeb on io');
