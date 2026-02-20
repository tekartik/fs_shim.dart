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
  File newFile(String path) => fs.file(newChildPath(path));

  /// Child link
  Link newLink(String path) => fs.link(newChildPath(path));

  /// Child path
  String newChildPath(String path) => fs.path.join(this.path, path);
}

/// Common extension helpers
extension FsShimDirectoryExtension on Directory {
  /// Tries to create a directory at [path]. Never throws.
  Future<bool> tryCreate() async {
    try {
      var type = await fs.type(path);
      if (type == FileSystemEntityType.directory) {
        return true;
      } else if (type != FileSystemEntityType.notFound) {
        return false;
      }
      final dir = directory(path);
      await dir.create(recursive: true);
      return true;
    } on FileSystemException catch (e) {
      // ignore
      if (e.status == FileSystemException.statusAlreadyExists) {
        return true;
      }
    } catch (_) {
      // ignore any error
    }
    return false;
  }

  /// Create a file system sandbox for this directory
  FileSystem sandbox() {
    return fs.sandbox(path: path);
  }
}
