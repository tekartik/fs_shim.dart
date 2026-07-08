// ignore_for_file: public_member_api_docs

library;

import 'dart:js_interop';
import 'dart:typed_data';

import 'package:fs_shim/fs.dart' as fs;
import 'package:fs_shim/src/common/bytes_utils.dart';

import 'opfs_file.dart';
import 'opfs_file_stat.dart';
import 'opfs_file_system.dart';
import 'opfs_file_system_entity.dart';
import 'opfs_file_system_exception.dart';
import 'opfs_fs.dart';
import 'opfs_interop.dart';

/// File system whose root "directory" contains exactly the given file handles,
/// each at `/<name>` (typically handles picked by the user through
/// `window.showOpenFilePicker()` or `window.showSaveFilePicker()`).
///
/// File handles give no access to their parent directory, so the structure is
/// fixed: files can be read and written (permission permitting) but not
/// created, deleted or renamed, and no directory can be created.
class FileSystemOpfsFileHandlesImpl extends FileSystemOpfsImpl {
  FileSystemOpfsFileHandlesImpl(this._fileHandles);

  /// Root entries, name to JS `FileSystemFileHandle`.
  final Map<String, OpfsFileHandle> _fileHandles;

  /// The handle at [path], or `null` if [path] is not `/<name>` of an entry.
  OpfsFileHandle? _handleAt(String path) {
    final segments = opfsPathSegments(path);
    if (segments.length == 1) {
      return _fileHandles[segments.first];
    }
    return null;
  }

  UnsupportedError _unsupported(String operation) => UnsupportedError(
    '$operation is not supported on a file system made of file handles',
  );

  @override
  bool operator ==(Object other) => identical(this, other);

  @override
  int get hashCode => identityHashCode(this);

  @override
  Future<fs.FileSystemEntityType> type(
    String path, {
    bool followLinks = true,
  }) async {
    if (opfsPathSegments(path).isEmpty) {
      return fs.FileSystemEntityType.directory;
    }
    return _handleAt(path) != null
        ? fs.FileSystemEntityType.file
        : fs.FileSystemEntityType.notFound;
  }

  @override
  Future<OpfsFileStat> stat(String path) async {
    final stat = OpfsFileStat();
    if (opfsPathSegments(path).isEmpty) {
      stat.type = fs.FileSystemEntityType.directory;
      return stat;
    }
    final handle = _handleAt(path);
    if (handle == null) {
      stat.type = fs.FileSystemEntityType.notFound;
      return stat;
    }
    final file = await handle.getFile().toDart;
    stat.type = fs.FileSystemEntityType.file;
    stat.size = file.size;
    stat.modified = DateTime.fromMillisecondsSinceEpoch(
      file.lastModified.round(),
    );
    return stat;
  }

  @override
  Future<void> createDirectory(String path, {bool recursive = false}) async {
    if (opfsPathSegments(path).isEmpty) {
      // Root always exists.
      return;
    }
    throw _unsupported('createDirectory');
  }

  @override
  Future<void> createFile(String path, {bool recursive = false}) async {
    if (opfsPathSegments(path).isEmpty) {
      throw opfsIsADirectoryException(path, 'Creation failed');
    }
    if (_handleAt(path) != null) {
      // Leave untouched.
      return;
    }
    throw _unsupported('createFile');
  }

  @override
  Future<void> delete(
    fs.FileSystemEntityType type,
    String path, {
    bool recursive = false,
  }) async {
    throw _unsupported('delete');
  }

  @override
  Future<void> rename(
    fs.FileSystemEntityType type,
    String path,
    String newPath,
  ) async {
    throw _unsupported('rename');
  }

  @override
  Future<void> copyFile(fs.File file, String newPath) async {
    final src = _handleAt(file.path);
    if (src == null) {
      throw opfsNotFoundException(file.path, 'Copy failed');
    }
    final dst = _handleAt(newPath);
    if (dst == null) {
      // Cannot create new files, only copy to another existing handle.
      throw _unsupported('copyFile to a path that is not a file handle');
    }
    await opfsWriteFileHandle(dst, await opfsReadFileHandle(src));
  }

  @override
  Future<Uint8List> readFileBytes(String path) async {
    if (opfsPathSegments(path).isEmpty) {
      throw opfsIsADirectoryException(path, 'Read failed');
    }
    final handle = _handleAt(path);
    if (handle == null) {
      throw opfsNotFoundException(path, 'Read failed');
    }
    return opfsReadFileHandle(handle);
  }

  @override
  Future<void> writeFileBytes(
    String path,
    Uint8List bytes, {
    fs.FileMode mode = fs.FileMode.write,
  }) async {
    if (opfsPathSegments(path).isEmpty) {
      throw opfsIsADirectoryException(path, 'Write failed');
    }
    final handle = _handleAt(path);
    if (handle == null) {
      throw opfsNotFoundException(path, 'Write failed');
    }
    var content = bytes;
    if (mode == fs.FileMode.append) {
      final existing = await opfsReadFileHandle(handle);
      if (existing.isNotEmpty) {
        content = asUint8List([...existing, ...bytes]);
      }
    }
    await opfsWriteFileHandle(handle, content);
  }

  @override
  Stream<OpfsFileSystemEntity> list(
    String path, {
    bool recursive = false,
    bool followLinks = true,
  }) async* {
    if (opfsPathSegments(path).isNotEmpty) {
      if (_handleAt(path) != null) {
        throw opfsNotADirectoryException(path, 'List failed');
      }
      throw opfsNotFoundException(path, 'List failed');
    }
    for (final name in _fileHandles.keys) {
      yield OpfsFile(this, opfsPathContext.join('/', name));
    }
  }
}
