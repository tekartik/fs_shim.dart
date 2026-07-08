import 'opfs_fs.dart';

/// OPFS is only available on the web.
FileSystemOpfsWeb get fileSystemOpfsWebImpl =>
    throw UnimplementedError('fileSystemOpfsWeb is only supported on the web');

/// Only available on the web.
FileSystemOpfsWeb fileSystemOpfsWebWithRootHandleImpl(
  FileSystemOpfsWebDirectoryHandle rootDirectoryHandle,
) => throw UnimplementedError(
  'fileSystemOpfsWebWithRootHandle is only supported on the web',
);

/// Only available on the web.
Future<FileSystemOpfsWebDirectoryHandle>
fileSystemOpfsWebShowDirectoryPickerImpl([
  FileSystemOpfsWebShowDirectoryPickerOptions? options,
]) => throw UnimplementedError(
  'fileSystemOpfsWebShowDirectoryPicker is only supported on the web',
);

/// JS `FileSystemDirectoryHandle`, only available on the web (where it is
/// simply a `JSObject`).
abstract class FileSystemOpfsWebDirectoryHandle {}
