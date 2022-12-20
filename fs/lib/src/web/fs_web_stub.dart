import 'package:fs_shim/fs.dart';

/// The default browser file system on top of IndexedDB.
FileSystem get fileSystemWeb => _stub('fileSystemWeb');

/// FileSystem with pageSize (default being 16Kb).
FileSystem getFileSystemWeb({int? pageSize}) => _stub('getFileSystemWeb');

T _stub<T>(String message) {
  throw UnimplementedError(message);
}
