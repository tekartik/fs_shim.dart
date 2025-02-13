import 'package:fs_shim/fs_idb.dart';

/// The default browser file system on top of IndexedDB.
FileSystem get fileSystemWeb => _stub('fileSystemWeb', 'use `fileSystemIo`');

/// FileSystem with pageSize (default being 16Kb).
FileSystem getFileSystemWebImpl({FileSystemIdbOptions? options}) =>
    _stub('getFileSystemWeb', 'use `fileSystemIo`');

///
FileSystem newFileSystemWeb({
  required String name,
  FileSystemIdbOptions? options,
}) => _stub('newFileSystemWeb', 'use `fileSystemIo`');

T _stub<T>(String function, String message) {
  throw UnimplementedError('$function not supported on it. $message');
}
