import 'package:fs_shim/fs.dart';

/// IO file system.
FileSystem get fileSystemIoImpl => _stub('fileSystemIo');

T _stub<T>(String message) {
  throw UnimplementedError(message);
}
