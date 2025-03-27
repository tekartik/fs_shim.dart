import 'package:fs_shim/fs.dart';

/// Common extension helpers, private for now
extension FsShimDirectoryPrvExtension on Directory {
  /// Child directory
  Directory newDirectory(String path) {
    if (this.path == '.') {
      return fs.directory(path);
    } else if (path == '.') {
      return this;
    }
    return fs.directory(fs.path.join(this.path, path));
  }

  /// Child directory
  Directory newDirectoryWith({String? path}) =>
      path == null ? this : newDirectory(path);

  /// Child file
  File newFile(String path) => fs.file(fs.path.join(this.path, path));
}
