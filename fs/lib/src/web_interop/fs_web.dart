import 'package:fs_shim/fs_idb.dart';

import 'fs_web_stub.dart'
    if (dart.library.js_interop) 'fs_web_impl.dart'
    if (dart.library.io) 'fs_web_io.dart';

/// Web file system on top of IndexedDB (database `lfs.db`), the default
/// file system on the web.
///
/// Files are stored in 256 KiB pages: whole file reads and writes about as
/// fast as one record per file, random access, streams of any size. A file
/// stored in one record (fs_shim 2.7 and before, or [fileSystemWebNoPaging])
/// stays readable and is converted when next written. Web only: throws
/// `UnimplementedError` on io.
FileSystem get fileSystemWeb => fileSystemWebImpl;

/// [fileSystemWeb] without pages (the same database `lfs.db`): each file in
/// one record, as [fileSystemWeb] did up to fs_shim 2.7.
///
/// Only good for whole file reads and writes: a random access or a stream
/// loads (and a write rewrites) the whole file. A file stored with pages
/// stays readable and is converted when next written. Web only: throws
/// `UnimplementedError` on io.
FileSystem get fileSystemWebNoPaging => fileSystemWebNoPagingImpl;

/// Create a new web file system with some options (if [options] is null,
/// 256 KiB pages, as [fileSystemWeb]).
FileSystem newFileSystemWeb({
  required String name,
  FileSystemIdbOptions? options,
}) => newFileSystemWebImpl(name: name, options: options);

/// Web file system (database `lfs.db`) with options: [fileSystemWeb] if
/// [options] is null, [fileSystemWebNoPaging] without page size.
FileSystem getFileSystemWeb({FileSystemIdbOptions? options}) {
  return getFileSystemWebImpl(options: options);
}
