import 'package:fs_shim/fs_idb.dart';
import 'package:fs_shim/src/idb/idb_file_system_storage.dart';
import 'package:idb_shim/idb_client_native.dart';

/// The default browser file system on top of IndexedDB. Random access support is not optimized
final FileSystem fileSystemWebImpl = newFileSystemIdb(idbFactoryNative);

/// New file system on the web using a particular database
FileSystem newFileSystemWebImpl({
  required String name,
  FileSystemIdbOptions? options,
}) => newFileSystemIdb(
  idbFactoryNative,
  name,
).withIdbOptions(options: options ?? _defaultOptions);

FileSystemIdbOptions get _defaultOptions =>
    const FileSystemIdbOptions(pageSize: defaultPageSize);

/// FileSystem with options (if [options] is null, a default options with pageSize default being 16Kb).
FileSystem getFileSystemWebImpl({FileSystemIdbOptions? options}) {
  options ??= _defaultOptions;
  if (options.pageSize == null) {
    return fileSystemWebImpl;
  }
  return fileSystemWebImpl.withIdbOptions(options: options);
}
