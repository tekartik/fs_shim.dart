import 'package:fs_shim/fs_browser.dart';
import 'package:fs_shim/fs_idb.dart';
import 'package:fs_shim/src/idb/idb_file_system_storage.dart';
import 'package:idb_shim/idb_client_native.dart';

/// The default browser file system on top of IndexedDB. Random access support is not optimized
final FileSystem fileSystemWeb = newFileSystemIdb(idbFactoryNative);

/// FileSystem with options (if [options] is null, a default options with pageSize default being 16Kb).
FileSystem getFileSystemWebImpl({FileSystemIdbOptions? options}) {
  options ??= FileSystemIdbOptions(pageSize: defaultPageSize);
  if (options.pageSize == null) {
    return fileSystemWeb;
  }
  return fileSystemWeb.withWebOptions(options: options);
}
