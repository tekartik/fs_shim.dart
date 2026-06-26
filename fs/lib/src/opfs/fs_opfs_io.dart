import 'fs_opfs.dart';

/// OPFS is only available on the web (use `fileSystemIo` on native).
FileSystemOpfsWeb get fileSystemOpfsWebImpl => throw UnimplementedError(
  'fileSystemOpfsWeb is only supported on the web, use `fileSystemIo`',
);
