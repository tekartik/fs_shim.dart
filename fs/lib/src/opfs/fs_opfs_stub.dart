import 'opfs_fs.dart';

/// OPFS is only available on the web.
FileSystemOpfsWeb get fileSystemOpfsWebImpl =>
    throw UnimplementedError('fileSystemOpfsWeb is only supported on the web');

/// Only available on the web.
FileSystemOpfsWeb fileSystemOpfsWebWithRootHandleImpl(
  FileSystemOpfsWebDirectoryHandle rootDirectoryHandle,
) => throw UnimplementedError(
  'FileSystemOpfsWeb.withRootHandle is only supported on the web',
);

/// Only available on the web.
FileSystemOpfsWeb fileSystemOpfsWebWithFileHandlesImpl(
  List<FileSystemOpfsWebFileHandle> fileHandles,
) => throw UnimplementedError(
  'FileSystemOpfsWeb.withFileHandles is only supported on the web',
);

/// Only available on the web.
Future<FileSystemOpfsWebDirectoryHandle>
fileSystemOpfsWebShowDirectoryPickerImpl([
  FileSystemOpfsWebShowDirectoryPickerOptions? options,
]) => throw UnimplementedError(
  'FileSystemOpfsWeb.showDirectoryPicker is only supported on the web',
);

/// Only available on the web.
Future<List<FileSystemOpfsWebFileHandle>>
fileSystemOpfsWebShowOpenFilePickerImpl([
  FileSystemOpfsWebShowOpenFilePickerOptions? options,
]) => throw UnimplementedError(
  'FileSystemOpfsWeb.showOpenFilePicker is only supported on the web',
);

/// Only available on the web.
Future<FileSystemOpfsWebFileHandle> fileSystemOpfsWebShowSaveFilePickerImpl([
  FileSystemOpfsWebShowSaveFilePickerOptions? options,
]) => throw UnimplementedError(
  'FileSystemOpfsWeb.showSaveFilePicker is only supported on the web',
);

/// Only available on the web.
Future<bool> fileSystemOpfsWebRequestWritePermissionImpl(
  FileSystemOpfsWebFileSystemEntityHandle handle,
) => throw UnimplementedError(
  'FileSystemOpfsWeb.requestWritePermission is only supported on the web',
);

/// Only available on the web.
Future<FileSystemOpfsWebDirectoryHandle>
fileSystemOpfsWebStorageGetDirectoryImpl() => throw UnimplementedError(
  'FileSystemOpfsWeb.storageGetDirectory is only supported on the web',
);
