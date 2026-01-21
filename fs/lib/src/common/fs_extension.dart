import 'package:fs_shim/fs.dart';
import 'package:meta/meta.dart';

import 'fs_sandbox.dart';

/// File system extension.
extension FsShimFileSystemExtension on FileSystem {
  /// File system sandboxing
  /// Directory from an optional path, null meaning [currentDirectory],
  FileSystem sandbox({String? path}) {
    var rootPath = path ?? currentDirectory.path;
    if (this is FsShimSandboxedFileSystem) {
      return FsShimSandboxedFileSystemImpl(rootDirectory: directory(rootPath));
    }
    var normalizedRootPath = this.path.normalize(this.path.absolute(rootPath));
    return FsShimSandboxedFileSystemImpl(
      rootDirectory: directory(normalizedRootPath),
    );
  }

  /// Absolute path
  String absolutePath(String path) {
    path = removeDotStart(path);
    if (path == '.') {
      return currentDirectory.path;
    }
    if (this.path.isAbsolute(path)) {
      return path;
    } else {
      return this.path.join(currentDirectory.path, path);
    }
  }
}

/// File system extension (private)
@internal
extension FsShimFileSystemPrvExtension on FileSystem {
  String removeDotStart(String path) {
    var sep = this.path.separator;
    var dotStart = '.$sep';
    while (path.startsWith(dotStart)) {
      path = path.substring(dotStart.length);
    }
    return path;
  }
}
