import 'package:fs_shim/src/platform/platform.dart';

/// Io context
PlatformContextIo get platformContextIo =>
    throw UnsupportedError('platformContextIo on web');

/// Browser context
final PlatformContextBrowser platformContextBrowser = PlatformContextBrowser();

/// Common platform context
PlatformContext get platformContext => platformContextBrowser;
