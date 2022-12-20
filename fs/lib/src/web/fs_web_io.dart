import 'package:fs_shim/fs.dart';

/// The default browser file system on top of IndexedDB.
FileSystem get fileSystemWeb => _stub('fileSystemWeb', 'use `fileSystemIo`');

/// FileSystem with pageSize (default being 16Kb).
FileSystem getFileSystemWeb({int? pageSize}) =>
    _stub('getFileSystemWeb', 'use `fileSystemIo`');

T _stub<T>(String function, String message) {
  throw UnimplementedError('$function not supported on it. $message');
}
