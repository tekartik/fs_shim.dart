import 'package:fs_shim/fs_idb.dart';

/// IO file system.
FileSystem get fileSystemIoImpl =>
    _stub('fileSystemIo not supported on web. use `fileSystemWeb`');

T _stub<T>(String message) {
  throw UnimplementedError(message);
}
