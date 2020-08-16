import 'package:fs_shim/fs.dart';

/// IO file system.
FileSystem get fileSystemIo => _stub('fileSystemIo');

T _stub<T>(String message) {
  throw UnimplementedError(message);
}
