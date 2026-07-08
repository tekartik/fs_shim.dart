// ignore_for_file: public_member_api_docs

/// Minimal raw web interop to the Origin Private File System (OPFS) API.
///
/// Only the subset of
/// https://developer.mozilla.org/en-US/docs/Web/API/File_System_API/Origin_private_file_system
/// needed by the file system implementation is bound here. Everything is kept
/// private to the package.
library;

import 'dart:js_interop';
import 'dart:typed_data';

@JS('navigator')
external OpfsNavigator get _navigator;

/// `navigator` accessor.
OpfsNavigator get opfsNavigator => _navigator;

extension type OpfsNavigator._(JSObject _) implements JSObject {
  external OpfsStorageManager get storage;
}

extension type OpfsStorageManager._(JSObject _) implements JSObject {
  /// `navigator.storage.getDirectory()`, returns the OPFS root directory.
  external JSPromise<OpfsDirectoryHandle> getDirectory();
}

/// Base `FileSystemHandle`.
extension type OpfsHandle._(JSObject _) implements JSObject {
  /// `'file'` or `'directory'`.
  external String get kind;

  /// Entry name.
  external String get name;

  /// Current permission state (`'granted'`, `'denied'` or `'prompt'`).
  external JSPromise<JSString> queryPermission([
    OpfsHandlePermissionDescriptor descriptor,
  ]);

  /// Request permission, returns the new permission state (`'granted'`,
  /// `'denied'` or `'prompt'`). Chromium-only, requires a user gesture when
  /// actually prompting.
  external JSPromise<JSString> requestPermission([
    OpfsHandlePermissionDescriptor descriptor,
  ]);
}

extension type OpfsHandlePermissionDescriptor._(JSObject _)
    implements JSObject {
  /// [mode] is `'read'` or `'readwrite'`.
  external factory OpfsHandlePermissionDescriptor({String mode});
}

extension type OpfsGetFileOptions._(JSObject _) implements JSObject {
  external factory OpfsGetFileOptions({bool create});
}

extension type OpfsGetDirectoryOptions._(JSObject _) implements JSObject {
  external factory OpfsGetDirectoryOptions({bool create});
}

extension type OpfsRemoveOptions._(JSObject _) implements JSObject {
  external factory OpfsRemoveOptions({bool recursive});
}

extension type OpfsCreateWritableOptions._(JSObject _) implements JSObject {
  external factory OpfsCreateWritableOptions({bool keepExistingData});
}

/// `FileSystemDirectoryHandle`.
extension type OpfsDirectoryHandle._(JSObject _) implements OpfsHandle {
  external JSPromise<OpfsFileHandle> getFileHandle(
    String name, [
    OpfsGetFileOptions options,
  ]);

  external JSPromise<OpfsDirectoryHandle> getDirectoryHandle(
    String name, [
    OpfsGetDirectoryOptions options,
  ]);

  external JSPromise<JSAny?> removeEntry(
    String name, [
    OpfsRemoveOptions options,
  ]);

  /// Async iterator over the directory values (handles).
  external OpfsAsyncIterator values();
}

/// `FileSystemFileHandle`.
extension type OpfsFileHandle._(JSObject _) implements OpfsHandle {
  external JSPromise<OpfsFileBlob> getFile();

  external JSPromise<OpfsWritableFileStream> createWritable([
    OpfsCreateWritableOptions options,
  ]);
}

/// `FileSystemWritableFileStream`.
extension type OpfsWritableFileStream._(JSObject _) implements JSObject {
  external JSPromise<JSAny?> write(JSAny data);

  external JSPromise<JSAny?> seek(int position);

  external JSPromise<JSAny?> truncate(int size);

  external JSPromise<JSAny?> close();
}

/// `File` (a `Blob`) as returned by [OpfsFileHandle.getFile].
extension type OpfsFileBlob._(JSObject _) implements JSObject {
  external int get size;

  external double get lastModified;

  external JSPromise<JSArrayBuffer> arrayBuffer();
}

/// Async iterator helper as returned by [OpfsDirectoryHandle.values].
extension type OpfsAsyncIterator._(JSObject _) implements JSObject {
  external JSPromise<OpfsAsyncIteratorResult> next();
}

extension type OpfsAsyncIteratorResult._(JSObject _) implements JSObject {
  external bool get done;
  external OpfsHandle? get value;
}

/// Iterate the directory handle values.
Stream<OpfsHandle> opfsListValues(OpfsDirectoryHandle dir) async* {
  final iterator = dir.values();
  while (true) {
    final result = await iterator.next().toDart;
    if (result.done) {
      break;
    }
    final value = result.value;
    if (value != null) {
      yield value;
    }
  }
}

/// Read all the bytes of a file handle.
Future<Uint8List> opfsReadFileHandle(OpfsFileHandle handle) async {
  final file = await handle.getFile().toDart;
  final buffer = await file.arrayBuffer().toDart;
  return buffer.toDart.asUint8List();
}

/// Write all the bytes to a file handle, truncating any existing content.
Future<void> opfsWriteFileHandle(OpfsFileHandle handle, Uint8List bytes) async {
  final writable = await handle.createWritable().toDart;
  try {
    if (bytes.isNotEmpty) {
      await writable.write(bytes.toJS).toDart;
    }
  } finally {
    await writable.close().toDart;
  }
}
