/// Common platform context
class PlatformContext {
  bool get isIo => false;
}

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
  /// true if Linuxm
  ///
  bool isIoLinux = false;

  @override
  bool get isIo => true;
}

class PlatformContextBrowser extends PlatformContext {}
