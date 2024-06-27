import 'package:tekartik_fs_test/test_common.dart';

/// Io context
PlatformContext get platformContextIo =>
    throw UnsupportedError('platformContextIo on web');

/// Browser context
final PlatformContextBrowser platformContextBrowser = PlatformContextBrowser();
