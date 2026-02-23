import 'package:fs_shim/fs.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as path_prefix;

import 'fs_sandbox.dart';

/// File system extension.
extension FsShimFileSystemExtension on FileSystem {
  /// File system sandboxing
  /// Directory from an optional path, null meaning [currentDirectory],
  /// If the original is a sandbox, the tree is sanitized (i.e. never 2 levels
  /// of sandboxing.
  FileSystem sandbox({String? path}) {
    var self = this;
    if (self is FsShimSandboxedFileSystem) {
      if (path == null) {
        return self;
      }
      var delegateFs = self.rootDirectory.fs;
      var delegatePath = self.delegatePath(path);
      return FsShimSandboxedFileSystemImpl(
        rootDirectory: delegateFs.directory(delegatePath),
      );
    }
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

  /// Normalize a path, removing redundant separators and up-level references.
  String normalizePath(String path) => p.normalize(path);

  /// Absolute path, normalized and with dot separators removed.
  /// If [path] is already absolute, it is returned as is
  /// (after normalization and dot separator removal).
  /// Otherwise, it is joined with the path of [currentDirectory]
  /// to form an absolute path.
  String absolutePath(String path) {
    path = removeDotSep(path);
    if (path == '.') {
      return normalizePath(currentDirectory.path);
    }
    if (this.path.isAbsolute(path)) {
      return normalizePath(path);
    } else {
      return normalizePath(this.path.join(currentDirectory.path, path));
    }
  }

  /// Path hash code based on absolute paths.
  int pathHashCode(String path) {
    var absPath = absolutePath(path);
    return absPath.hashCode;
  }

  /// Path equality based on absolute paths.
  bool pathEquals(String path1, String path2) {
    var absPath1 = absolutePath(path1);
    var absPath2 = absolutePath(path2);
    return absPath1 == absPath2;
  }

  /// Unsandbox a file system, returning the root directory of the sandbox.
  /// return [currentDirectory] if not sandboxed.
  Directory unsandbox({String? path}) {
    if (this is FsShimSandboxedFileSystem) {
      /// Handle absolute file
      if (path != null && path.startsWith(this.path.separator)) {
        path = path.substring(1);
      }
      return (this as FsShimSandboxedFileSystem).rootDirectory.directoryWith(
        path: path,
      );
    } else {
      return currentDirectory.directoryWith(path: path);
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
