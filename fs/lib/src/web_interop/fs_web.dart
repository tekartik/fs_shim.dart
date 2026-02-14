import 'package:fs_shim/fs_idb.dart';

import 'fs_web_stub.dart'
    if (dart.library.js_interop) 'fs_web_impl.dart'
    if (dart.library.io) 'fs_web_io.dart';

/// Web file system on top of IndexedDB.
FileSystem get fileSystemWeb => fileSystemWebImpl;

/// Create a new web file system with some options.
FileSystem newFileSystemWeb({
  required String name,
  FileSystemIdbOptions? options,
}) => newFileSystemWebImpl(name: name, options: options);

/// Web file system with options (if [options] is null, a default options with pageSize default being 16Kb).
FileSystem getFileSystemWeb({FileSystemIdbOptions? options}) {
  return getFileSystemWebImpl(options: options);
}
