import 'fs_opfs.dart';

/// OPFS is only available on the web.
FileSystemOpfsWeb get fileSystemOpfsWebImpl =>
    throw UnimplementedError('fileSystemOpfsWeb is only supported on the web');

/// Only available on the web.
FileSystemOpfsWeb fileSystemOpfsWebWithRootHandleImpl(
  Object rootDirectoryHandle,
) => throw UnimplementedError(
  'fileSystemOpfsWebWithRootHandle is only supported on the web',
);
