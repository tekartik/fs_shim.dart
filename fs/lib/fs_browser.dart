import 'package:fs_shim/fs_idb.dart';
import 'package:fs_shim/src/web/fs_web.dart';
export 'package:fs_shim/src/web/fs_web.dart';

/// Idb file system options.
class FileSystemIdbOptions {
  /// Default page size (null means no page).
  final int? pageSize;

  /// Idb file system options.
  FileSystemIdbOptions({this.pageSize});
}

/// The default browser file system on top of IndexedDB.
FileSystem get fileSystemIdb => fileSystemWeb;

/// Get a file system with some options.
///
/// if [options] is null a default options with 16Kb page is created
FileSystem getFileSystemIdb({FileSystemIdbOptions? options}) =>
    getFileSystemWebImpl(options: options);
