import 'package:fs_shim/fs.dart';

/// The default browser file system on top of IndexedDB.
FileSystem get fileSystemWeb =>
    _stub('fileSystemWeb not supported on io. use `fileSystemIo`');

T _stub<T>(String message) {
  throw UnimplementedError(message);
}
