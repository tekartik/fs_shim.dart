import 'package:fs_shim/fs.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as path_prefix;

import 'fs_sandbox.dart';

/// File system extension.
extension FsShimFileSystemExtension on FileSystem {
  /// File system sandboxing
  /// Directory from an optional path, null meaning [currentDirectory],
  FileSystem sandbox({String? path}) {
    var absPath = p.normalize(
      path == null ? currentDirectory.path : absolutePath(path),
    );
    /*
    if (this is FsShimSandboxedFileSystem) {
      return FsShimSandboxedFileSystemImpl(rootDirectory: directory(absPath));
    }
    var normalizedRootPath = this.path.normalize(this.path.absolute(absPath));*/
    return FsShimSandboxedFileSystemImpl(rootDirectory: directory(absPath));
  }

  /// Absolute path
  String absolutePath(String path) {
    path = removeDotSep(path);
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
  path_prefix.Context get p => path;
  String removeDotSep(String path) {
    var sep = p.separator;
    var dotSep = '.$sep';
    while (path.startsWith(dotSep)) {
      path = path.substring(dotSep.length);
    }
    return path;
  }
}
