import 'package:fs_shim/fs_idb.dart';
import 'package:fs_shim/src/idb/idb_file_system_storage.dart';
import 'package:idb_shim/idb_client_native.dart';

/// The browser file system on top of IndexedDB (`lfs.db`), one record per
/// file.
final FileSystem fileSystemWebNoPagingImpl = newFileSystemIdb(idbFactoryNative);

/// The default browser file system: [fileSystemWebNoPagingImpl] (the same
/// database) with [webDefaultPageSize] pages.
final FileSystem fileSystemWebImpl = fileSystemWebNoPagingImpl.withIdbOptions(
  options: _defaultOptions,
);

/// New file system on the web using a particular database
FileSystem newFileSystemWebImpl({
  required String name,
  FileSystemIdbOptions? options,
}) => newFileSystemIdb(
  idbFactoryNative,
  name,
).withIdbOptions(options: options ?? _defaultOptions);

const _defaultOptions = FileSystemIdbOptions(pageSize: webDefaultPageSize);

/// FileSystem with options (if [options] is null, [fileSystemWebImpl]; no
/// page size, [fileSystemWebNoPagingImpl]).
FileSystem getFileSystemWebImpl({FileSystemIdbOptions? options}) {
  if (options == null) {
    return fileSystemWebImpl;
  }
  if ((options.pageSize ?? 0) == 0) {
    return fileSystemWebNoPagingImpl;
  }
  return fileSystemWebNoPagingImpl.withIdbOptions(options: options);
}
