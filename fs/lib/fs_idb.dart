library;

import 'package:fs_shim/src/idb/idb_file_system_storage.dart';
import 'package:fs_shim/src/idb/idb_fs.dart';
import 'package:idb_shim/idb.dart' as idb;
import 'package:meta/meta.dart';

import 'fs.dart';

export 'fs.dart';
export 'src/idb/idb_file_system.dart' show FileSystemIdbExt;

/// Idb file system options.
class FileSystemIdbOptions {
  /// Default page size (null means no page).
  final int? pageSize;

  /// Idb file system options.
  const FileSystemIdbOptions({this.pageSize});

  @override
  String toString() => 'pageSize: $pageSize';

  /// noPage means not optimized for random access and file streaming
  /// but optimized for full read and write.
  static const noPage = FileSystemIdbOptions();

  /// [pageDefault] means using 16Kb page.
  static const pageDefault = FileSystemIdbOptions(pageSize: defaultPageSize);
}

/// Internal options helper.
@visibleForTesting
extension FileSystemIdbOptionsExt on FileSystemIdbOptions {
  /// True if it as page size options
  bool get hasPageSize => (pageSize ?? 0) != 0;

  /// 0 for none
  int get filePageSize => pageSize ?? 0;

  /// Expected page size when writing.
  int get expectedPageSize => idbSupportsV2Format ? filePageSize : 0;

  /// Debug name
  String get debugName => '$filePageSize';
}

///
/// Idb implementation (base for memory and browser)
///
FileSystem newFileSystemIdb(idb.IdbFactory idbFactory, [String? dbPath]) =>
    FileSystemIdb(idbFactory, dbPath: dbPath);

/// Prefer newFileSystemIdb
@Deprecated('use newFileSystemIdb')
FileSystem newIdbFileSystem(idb.IdbFactory idbFactory, [String? name]) =>
    newFileSystemIdb(idbFactory, name);
