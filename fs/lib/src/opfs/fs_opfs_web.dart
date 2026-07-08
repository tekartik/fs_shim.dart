import 'dart:js_interop';

import 'opfs_file_system.dart';
import 'opfs_fs.dart';
import 'opfs_interop.dart';

/// JS `FileSystemDirectoryHandle`, any interop binding works (`package:web`,
/// raw `dart:js_interop`, ...).
typedef FileSystemOpfsWebDirectoryHandle = JSObject;

/// `window.showDirectoryPicker()` (File System Access API), not exposed by
/// `package:web`. Chromium-only, must be called from a user gesture.
@JS('window.showDirectoryPicker')
external JSPromise<JSObject> _showDirectoryPicker([JSObject options]);

extension type _ShowDirectoryPickerOptions._(JSObject _) implements JSObject {
  external factory _ShowDirectoryPickerOptions();

  external set id(String value);

  external set mode(String value);

  external set startIn(JSAny value);
}

FileSystemOpfsWeb? _fileSystemOpfsWeb;

/// The OPFS (Origin Private File System) file system.
///
/// There is a single OPFS per origin, this returns a shared instance.
FileSystemOpfsWeb get fileSystemOpfsWebImpl =>
    _fileSystemOpfsWeb ??= FileSystemOpfsImpl();

/// File system rooted at an existing JS `FileSystemDirectoryHandle`.
FileSystemOpfsWeb fileSystemOpfsWebWithRootHandleImpl(
  FileSystemOpfsWebDirectoryHandle rootDirectoryHandle,
) {
  final handle = rootDirectoryHandle as OpfsDirectoryHandle;
  return FileSystemOpfsImpl(rootHandleProvider: () async => handle);
}

/// Prompts the user to select a directory using `window.showDirectoryPicker()`.
Future<FileSystemOpfsWebDirectoryHandle>
fileSystemOpfsWebShowDirectoryPickerImpl([
  FileSystemOpfsWebShowDirectoryPickerOptions? options,
]) async {
  final id = options?.id;
  final mode = options?.mode;
  final startIn = options?.startIn;
  if (id == null && mode == null && startIn == null) {
    return await _showDirectoryPicker().toDart;
  }
  final jsOptions = _ShowDirectoryPickerOptions();
  if (id != null) {
    jsOptions.id = id;
  }
  if (mode != null) {
    jsOptions.mode = mode;
  }
  if (startIn != null) {
    jsOptions.startIn = startIn is String ? startIn.toJS : startIn as JSAny;
  }
  return await _showDirectoryPicker(jsOptions).toDart;
}
