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
FileSystemOpfsWeb fileSystemOpfsWebWithFileHandlesImpl(
  List<FileSystemOpfsWebFileHandle> fileHandles,
) => throw UnimplementedError(
  'fileSystemOpfsWebWithFileHandles is only supported on the web',
);

/// Only available on the web.
Future<FileSystemOpfsWebDirectoryHandle>
fileSystemOpfsWebShowDirectoryPickerImpl([
  FileSystemOpfsWebShowDirectoryPickerOptions? options,
]) => throw UnimplementedError(
  'fileSystemOpfsWebShowDirectoryPicker is only supported on the web',
);

/// Only available on the web.
Future<List<FileSystemOpfsWebFileHandle>>
fileSystemOpfsWebShowOpenFilePickerImpl([
  FileSystemOpfsWebShowOpenFilePickerOptions? options,
]) => throw UnimplementedError(
  'fileSystemOpfsWebShowOpenFilePicker is only supported on the web',
);

/// Only available on the web.
Future<FileSystemOpfsWebFileHandle> fileSystemOpfsWebShowSaveFilePickerImpl([
  FileSystemOpfsWebShowSaveFilePickerOptions? options,
]) => throw UnimplementedError(
  'fileSystemOpfsWebShowSaveFilePicker is only supported on the web',
);

/// Only available on the web.
Future<bool> fileSystemOpfsWebRequestWritePermissionImpl(Object handle) =>
    throw UnimplementedError(
      'fileSystemOpfsWebRequestWritePermission is only supported on the web',
    );

/// JS `FileSystemDirectoryHandle`, only available on the web (where it is
/// simply a `JSObject`).
abstract class FileSystemOpfsWebDirectoryHandle {}

/// JS `FileSystemFileHandle`, only available on the web (where it is
/// simply a `JSObject`).
abstract class FileSystemOpfsWebFileHandle {}
