/// Legacy version which was not wasm compatible
library;

import 'package:fs_shim/fs_idb.dart';
import 'package:fs_shim/src/web_interop/fs_web.dart';

export 'package:fs_shim/fs_idb.dart';
export 'package:fs_shim/src/web_interop/fs_web.dart';

/// The default browser file system on top of IndexedDB.
@Deprecated('Use fileSystemIdb from fs_browser')
FileSystem get fileSystemIdb => fileSystemWeb;

/// Get a file system with some options.
///
/// if [options] is null a default options with 16Kb page is created
FileSystem getFileSystemWeb({FileSystemIdbOptions? options}) =>
    getFileSystemWebImpl(options: options);
