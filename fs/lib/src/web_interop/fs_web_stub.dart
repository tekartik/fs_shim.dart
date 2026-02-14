import 'package:fs_shim/fs_idb.dart';

/// The default browser file system on top of IndexedDB.
FileSystem get fileSystemWebImpl => _stub('fileSystemWeb');

/// Browser base file system With a custom indexed db
FileSystem newFileSystemWebImpl({
  required String name,
  FileSystemIdbOptions? options,
}) => _stub('newFileSystemWeb');

/// FileSystem with pageSize (default being 16Kb).
FileSystem getFileSystemWebImpl({FileSystemIdbOptions? options}) =>
    _stub('getFileSystemWeb');

T _stub<T>(String message) {
  throw UnimplementedError(message);
}
