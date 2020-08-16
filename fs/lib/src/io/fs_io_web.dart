import 'package:fs_shim/fs_idb.dart';

/// IO file system.
FileSystem get fileSystemIo =>
    _stub('fileSystemIo not supported on web. use `fileSystemWeb`');

T _stub<T>(String message) {
  throw UnimplementedError(message);
}
