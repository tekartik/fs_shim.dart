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
Future<String> fileSystemOpfsWebQueryPermissionImpl(
  FileSystemOpfsWebFileSystemEntityHandle handle, {
  required String mode,
}) => throw UnimplementedError(
  'FileSystemOpfsWeb.queryPermission is only supported on the web',
);

/// Only available on the web.
Future<String> fileSystemOpfsWebRequestPermissionImpl(
  FileSystemOpfsWebFileSystemEntityHandle handle, {
  required String mode,
}) => throw UnimplementedError(
  'FileSystemOpfsWeb.requestPermission is only supported on the web',
);

/// Only available on the web.
FileSystemOpfsWebFileHandle fileSystemOpfsWebFileHandleFromJsObjectImpl(
  Object jsObject,
) => throw UnimplementedError(
  'FileSystemOpfsWebFileHandle.fromJsObject is only supported on the web',
);

/// Only available on the web.
FileSystemOpfsWebDirectoryHandle
fileSystemOpfsWebDirectoryHandleFromJsObjectImpl(
  Object jsObject,
) => throw UnimplementedError(
  'FileSystemOpfsWebDirectoryHandle.fromJsObject is only supported on the web',
);

/// Only available on the web.
Object fileSystemOpfsWebHandleJsObjectImpl(
  FileSystemOpfsWebFileSystemEntityHandle handle,
) => throw UnimplementedError(
  'FileSystemOpfsWebFileSystemEntityHandle.jsObject is only supported on the web',
);

/// Only available on the web.
String fileSystemOpfsWebHandleNameImpl(
  FileSystemOpfsWebFileSystemEntityHandle handle,
) => throw UnimplementedError(
  'FileSystemOpfsWebFileSystemEntityHandle.name is only supported on the web',
);

/// Only available on the web.
Future<FileSystemOpfsWebDirectoryHandle>
fileSystemOpfsWebStorageGetDirectoryImpl() => throw UnimplementedError(
  'FileSystemOpfsWeb.storageGetDirectory is only supported on the web',
);
