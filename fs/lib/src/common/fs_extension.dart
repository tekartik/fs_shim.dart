import 'package:fs_shim/fs.dart';

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
    if (this.path.isAbsolute(path)) {
      return path;
    } else {
      return this.path.join(currentDirectory.path, path);
    }
  }
}
