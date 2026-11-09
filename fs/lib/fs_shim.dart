/// A portable, asynchronous `File`/`Directory`/`Link` API (a subset of
/// `dart:io`) behind a [FileSystem], plus the main instances:
///
/// * [fileSystemDefault]: io on the Dart VM and Flutter native, IndexedDB
///   in the browser; the `File(path)`, `Directory(path)` and `Link(path)`
///   constructors use it.
/// * [fileSystemIo]: `dart:io` (not on the web).
/// * [fileSystemWeb]: IndexedDB (web only).
/// * [fileSystemMemory]: in memory, shared (see `newFileSystemMemory` in
///   `package:fs_shim/fs_memory.dart` for a new one).
///
/// OPFS is in `package:fs_shim/fs_opfs_web.dart`.
library;

export 'fs.dart';
export 'fs_browser.dart' show fileSystemWeb;
export 'fs_memory.dart' show fileSystemMemory;
export 'src/default/fs_default.dart' show fileSystemDefault;

/// @nodoc
export 'src/io/fs_io.dart' show fileSystemIo;
