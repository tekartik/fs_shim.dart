import 'package:fs_shim/fs_idb.dart';
import 'package:fs_shim/src/idb/idb_file_system.dart';
import 'package:idb_shim/idb_client_native.dart';

/// The default browser file system on top of IndexedDB.
final FileSystem fileSystemWeb = newFileSystemIdb(idbFactoryNative);

/// Default page size
const defaultPageSize = 64 * 1024;
var _fileSystemByPageSize = <int, FileSystem>{};

/// FileSystem with pageSize (default being 16Kb).
FileSystem getFileSystemWeb({int? pageSize}) {
  pageSize ??= defaultPageSize;
  return _fileSystemByPageSize[pageSize] ??=
      IdbFileSystem(idbFactoryNative, null, pageSize: pageSize);
}
