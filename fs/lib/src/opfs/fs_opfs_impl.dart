import 'dart:js_interop';

import 'fs_opfs.dart';
import 'opfs_file_system.dart';
import 'opfs_interop.dart';

/// `window.showDirectoryPicker()` (File System Access API), not exposed by
/// `package:web`. Chromium-only, must be called from a user gesture.
@JS('window.showDirectoryPicker')
external JSPromise<JSObject> _showDirectoryPicker();

FileSystemOpfsWeb? _fileSystemOpfsWeb;

/// The OPFS (Origin Private File System) file system.
///
/// There is a single OPFS per origin, this returns a shared instance.
FileSystemOpfsWeb get fileSystemOpfsWebImpl =>
    _fileSystemOpfsWeb ??= FileSystemOpfsImpl();

/// File system rooted at an existing JS `FileSystemDirectoryHandle`.
FileSystemOpfsWeb fileSystemOpfsWebWithRootHandleImpl(
  Object rootDirectoryHandle,
) {
  final handle = rootDirectoryHandle as OpfsDirectoryHandle;
  return FileSystemOpfsImpl(rootHandleProvider: () async => handle);
}

/// Prompts the user to select a directory using `window.showDirectoryPicker()`.
Future<Object> fileSystemOpfsWebShowDirectoryPickerImpl() async =>
    await _showDirectoryPicker().toDart;
