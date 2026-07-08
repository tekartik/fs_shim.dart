import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'opfs_file_handles_file_system.dart';
import 'opfs_file_system.dart';
import 'opfs_fs.dart';
import 'opfs_interop.dart';

/// Base JS `FileSystemHandle` wrapper.
abstract class _FsOpfsWebHandle
    implements FileSystemOpfsWebFileSystemEntityHandle {
  _FsOpfsWebHandle(this.jsObject);

  final JSObject jsObject;

  OpfsHandle get _handle => jsObject as OpfsHandle;
}

/// Wraps a JS `FileSystemDirectoryHandle`, any interop binding works
/// (`package:web`, raw `dart:js_interop`, ...).
class FileSystemOpfsWebDirectoryHandleWeb extends _FsOpfsWebHandle
    implements FileSystemOpfsWebDirectoryHandle {
  /// Wraps [jsObject], a JS `FileSystemDirectoryHandle`.
  FileSystemOpfsWebDirectoryHandleWeb(super.jsObject);
}

/// Wraps a JS `FileSystemFileHandle`, any interop binding works
/// (`package:web`, raw `dart:js_interop`, ...).
class FileSystemOpfsWebFileHandleWeb extends _FsOpfsWebHandle
    implements FileSystemOpfsWebFileHandle {
  /// Wraps [jsObject], a JS `FileSystemFileHandle`.
  FileSystemOpfsWebFileHandleWeb(super.jsObject);
}

/// `window.showDirectoryPicker()` (File System Access API), not exposed by
/// `package:web`. Chromium-only, must be called from a user gesture.
@JS('window.showDirectoryPicker')
external JSPromise<JSObject> _showDirectoryPicker([JSObject options]);

/// `window.showOpenFilePicker()` (File System Access API), not exposed by
/// `package:web`. Chromium-only, must be called from a user gesture.
@JS('window.showOpenFilePicker')
external JSPromise<JSArray<JSObject>> _showOpenFilePicker([JSObject options]);

/// `window.showSaveFilePicker()` (File System Access API), not exposed by
/// `package:web`. Chromium-only, must be called from a user gesture.
@JS('window.showSaveFilePicker')
external JSPromise<JSObject> _showSaveFilePicker([JSObject options]);

extension type _ShowDirectoryPickerOptions._(JSObject _) implements JSObject {
  factory _ShowDirectoryPickerOptions() =>
      JSObject() as _ShowDirectoryPickerOptions;

  external set id(String value);

  external set mode(String value);

  external set startIn(JSAny value);
}

extension type _ShowOpenFilePickerOptions._(JSObject _) implements JSObject {
  factory _ShowOpenFilePickerOptions() =>
      JSObject() as _ShowOpenFilePickerOptions;

  external set id(String value);

  external set startIn(JSAny value);

  external set multiple(bool value);

  external set excludeAcceptAllOption(bool value);

  external set types(JSArray<JSObject> value);
}

extension type _ShowSaveFilePickerOptions._(JSObject _) implements JSObject {
  factory _ShowSaveFilePickerOptions() =>
      JSObject() as _ShowSaveFilePickerOptions;

  external set id(String value);

  external set startIn(JSAny value);

  external set suggestedName(String value);

  external set excludeAcceptAllOption(bool value);

  external set types(JSArray<JSObject> value);
}

extension type _FilePickerAcceptType._(JSObject _) implements JSObject {
  factory _FilePickerAcceptType() => JSObject() as _FilePickerAcceptType;

  external set description(String value);

  external set accept(JSObject value);
}

JSAny _startInToJs(Object startIn) =>
    startIn is String ? startIn.toJS : startIn as JSAny;

JSArray<JSObject> _acceptTypesToJs(
  List<FileSystemOpfsWebFilePickerAcceptType> types,
) => [for (final type in types) _acceptTypeToJs(type)].toJS;

JSObject _acceptTypeToJs(FileSystemOpfsWebFilePickerAcceptType type) {
  final jsType = _FilePickerAcceptType();
  final description = type.description;
  if (description != null) {
    jsType.description = description;
  }
  final accept = JSObject();
  type.accept.forEach((mimeType, extensions) {
    accept.setProperty(
      mimeType.toJS,
      [for (final extension in extensions) extension.toJS].toJS,
    );
  });
  jsType.accept = accept;
  return jsType;
}

FileSystemOpfsWeb? _fileSystemOpfsWeb;

extension on FileSystemOpfsWebFileSystemEntityHandle {
  JSObject get jsObject => (this as _FsOpfsWebHandle)._handle;
}

/// The OPFS (Origin Private File System) file system.
///
/// There is a single OPFS per origin, this returns a shared instance.
FileSystemOpfsWeb get fileSystemOpfsWebImpl =>
    _fileSystemOpfsWeb ??= FileSystemOpfsImpl();

/// File system rooted at an existing JS `FileSystemDirectoryHandle`.
FileSystemOpfsWeb fileSystemOpfsWebWithRootHandleImpl(
  FileSystemOpfsWebDirectoryHandle rootDirectoryHandle,
) {
  final handle = rootDirectoryHandle.jsObject as OpfsDirectoryHandle;
  return FileSystemOpfsImpl(rootHandleProvider: () async => handle);
}

/// File system whose root contains the given JS `FileSystemFileHandle`s.
FileSystemOpfsWeb fileSystemOpfsWebWithFileHandlesImpl(
  List<FileSystemOpfsWebFileHandle> fileHandles,
) {
  final map = <String, OpfsFileHandle>{};
  for (final fileHandle in fileHandles) {
    final handle = fileHandle.jsObject as OpfsFileHandle;
    var name = handle.name;
    if (map.containsKey(name)) {
      // Handles picked from different directories can share a name,
      // deduplicate ('file.txt', 'file (1).txt', 'file (2).txt', ...).
      final basename = opfsPathContext.basenameWithoutExtension(name);
      final extension = opfsPathContext.extension(name);
      var index = 1;
      while (map.containsKey(name)) {
        name = '$basename (${index++})$extension';
      }
    }
    map[name] = handle;
  }
  return FileSystemOpfsFileHandlesImpl(map);
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
    return FileSystemOpfsWebDirectoryHandleWeb(
      await _showDirectoryPicker().toDart,
    );
  }
  final jsOptions = _ShowDirectoryPickerOptions();
  if (id != null) {
    jsOptions.id = id;
  }
  if (mode != null) {
    jsOptions.mode = mode;
  }
  if (startIn != null) {
    jsOptions.startIn = _startInToJs(startIn);
  }
  return FileSystemOpfsWebDirectoryHandleWeb(
    await _showDirectoryPicker(jsOptions).toDart,
  );
}

/// Prompts the user to select file(s) using `window.showOpenFilePicker()`.
Future<List<FileSystemOpfsWebFileHandle>>
fileSystemOpfsWebShowOpenFilePickerImpl([
  FileSystemOpfsWebShowOpenFilePickerOptions? options,
]) async {
  final id = options?.id;
  final startIn = options?.startIn;
  final multiple = options?.multiple;
  final excludeAcceptAllOption = options?.excludeAcceptAllOption;
  final types = options?.types;
  print('#1');
  if (id == null &&
      startIn == null &&
      multiple == null &&
      excludeAcceptAllOption == null &&
      types == null) {
    return _wrapFileHandles(await _showOpenFilePicker().toDart);
  }
  print('#2');
  final jsOptions = JSObject() as _ShowOpenFilePickerOptions;
  print('#3');
  if (id != null) {
    jsOptions.id = id;
  }
  if (startIn != null) {
    jsOptions.startIn = _startInToJs(startIn);
  }
  if (multiple != null) {
    jsOptions.multiple = multiple;
  }
  if (excludeAcceptAllOption != null) {
    jsOptions.excludeAcceptAllOption = excludeAcceptAllOption;
  }
  if (types != null) {
    jsOptions.types = _acceptTypesToJs(types);
  }
  return _wrapFileHandles(await _showOpenFilePicker(jsOptions).toDart);
}

List<FileSystemOpfsWebFileHandle> _wrapFileHandles(
  JSArray<JSObject> handles,
) => [
  for (final handle in handles.toDart) FileSystemOpfsWebFileHandleWeb(handle),
];

/// Prompts the user to select a file to save to using
/// `window.showSaveFilePicker()`.
Future<FileSystemOpfsWebFileHandle> fileSystemOpfsWebShowSaveFilePickerImpl([
  FileSystemOpfsWebShowSaveFilePickerOptions? options,
]) async {
  final id = options?.id;
  final startIn = options?.startIn;
  final suggestedName = options?.suggestedName;
  final excludeAcceptAllOption = options?.excludeAcceptAllOption;
  final types = options?.types;
  if (id == null &&
      startIn == null &&
      suggestedName == null &&
      excludeAcceptAllOption == null &&
      types == null) {
    return FileSystemOpfsWebFileHandleWeb(await _showSaveFilePicker().toDart);
  }
  final jsOptions = _ShowSaveFilePickerOptions();
  if (id != null) {
    jsOptions.id = id;
  }
  if (startIn != null) {
    jsOptions.startIn = _startInToJs(startIn);
  }
  if (suggestedName != null) {
    jsOptions.suggestedName = suggestedName;
  }
  if (excludeAcceptAllOption != null) {
    jsOptions.excludeAcceptAllOption = excludeAcceptAllOption;
  }
  if (types != null) {
    jsOptions.types = _acceptTypesToJs(types);
  }
  return FileSystemOpfsWebFileHandleWeb(
    await _showSaveFilePicker(jsOptions).toDart,
  );
}

/// Requests `readwrite` permission on a `FileSystemHandle` wrapper (file or
/// directory handle), returns true if granted.
Future<bool> fileSystemOpfsWebRequestWritePermissionImpl(
  FileSystemOpfsWebFileSystemEntityHandle handle,
) async {
  final jsHandle = (handle as _FsOpfsWebHandle)._handle;
  final state = await jsHandle
      .requestPermission(OpfsHandlePermissionDescriptor(mode: 'readwrite'))
      .toDart;
  return state.toDart == 'granted';
}

/// Returns the OPFS root directory handle using `navigator.storage.getDirectory()`.
Future<FileSystemOpfsWebDirectoryHandle>
fileSystemOpfsWebStorageGetDirectoryImpl() async {
  final handle = await opfsNavigator.storage.getDirectory().toDart;
  return FileSystemOpfsWebDirectoryHandleWeb(handle);
}
