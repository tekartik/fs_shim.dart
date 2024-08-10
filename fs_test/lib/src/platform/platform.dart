export 'platform_io.dart' if (dart.library.js_interop) 'platform_web.dart';

/// Common platform context
class PlatformContext {
  /// True on io (native fs)
  bool get isIo => false;
}

/// IO && node only
class PlatformContextIo extends PlatformContext {
  ///
  /// true if windows operating system
  ///
  bool isIoWindows = false;

  ///
  /// true if OS X operating system
  ///
  bool isIoMacOS = false;

  ///
  /// true if Linux
  ///
  bool isIoLinux = false;

  /// True on node (can be windows, mac or linux)
  bool get isIoNode => false;

  @override
  bool get isIo => true;
}

/// Browser only
class PlatformContextBrowser extends PlatformContext {}
