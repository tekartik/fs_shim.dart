import 'package:fs_shim/src/platform/platform.dart';

/// Io context
PlatformContext get platformContextIo =>
    throw UnsupportedError('platformContextIo on web');

/// Browser context
final PlatformContextBrowser platformContextBrowser = PlatformContextBrowser();
