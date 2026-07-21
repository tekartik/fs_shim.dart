import 'package:fs_shim/fs.dart';

/// File extension.
extension FsShimFileExtension on File {
  /// Unsandbox this file, returning the corresponding file in the underlying
  /// (non-sandboxed) delegate file system.
  ///
  /// Returns this file unchanged if its file system is not sandboxed.
  File unsandbox() {
    var fileSystem = fs;
    if (fileSystem is FsShimSandboxedFileSystem) {
      return fileSystem.rootDirectory.fs.file(fileSystem.delegatePath(path));
    }
    return this;
  }
}
