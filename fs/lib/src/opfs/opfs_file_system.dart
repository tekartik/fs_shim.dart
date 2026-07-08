// ignore_for_file: public_member_api_docs

library;

import 'dart:js_interop';
import 'dart:typed_data';

import 'package:fs_shim/fs.dart' as fs;
import 'package:fs_shim/src/common/bytes_utils.dart';
import 'package:fs_shim/src/common/fs_mixin.dart';
import 'package:fs_shim/src/common/import.dart';
import 'package:fs_shim/src/common/memory_sink.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;

import 'opfs_directory.dart';
import 'opfs_file.dart';
import 'opfs_file_stat.dart';
import 'opfs_file_system_entity.dart';
import 'opfs_file_system_exception.dart';
import 'opfs_fs.dart';
import 'opfs_interop.dart';

/// OPFS file system implementation.
class FileSystemOpfsImpl extends Object
    with FileSystemMixin
    implements FileSystemOpfsWeb {
  /// By default the root is the OPFS root (`navigator.storage.getDirectory()`,
  /// unique per origin, a shared instance is used).
  ///
  /// A custom [rootHandleProvider] can be given to root the file system at any
  /// `FileSystemDirectoryHandle` (e.g. picked by the user through
  /// `window.showDirectoryPicker()`).
  FileSystemOpfsImpl({this._rootHandleProvider});

  final Future<OpfsDirectoryHandle> Function()? _rootHandleProvider;

  OpfsDirectoryHandle? _root;

  Future<OpfsDirectoryHandle> get _rootHandle async => _root ??=
      await (_rootHandleProvider?.call() ??
          opfsNavigator.storage.getDirectory().toDart);

  @override
  String get name => 'opfs';

  @override
  bool get supportsLink => false;

  @override
  bool get supportsFileLink => false;

  @override
  bool get supportsRandomAccess => false;

  @override
  p.Context get path => opfsPathContext;

  @override
  p.Context get pathContext => path;

  @override
  fs.Directory directory(String path) => OpfsDirectory(this, path);

  @override
  fs.File file(String path) => OpfsFile(this, path);

  @override
  fs.Link link(String path) =>
      throw UnsupportedError('Links are not supported on OPFS');

  @override
  fs.Directory get currentDirectory => directory(path.current);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FileSystemOpfsImpl &&
          runtimeType == other.runtimeType &&
          _rootHandleProvider == null &&
          other._rootHandleProvider == null);

  @override
  int get hashCode => name.hashCode;

  @override
  String toString() => name;

  // ---------------------------------------------------------------------------
  // Internal navigation helpers
  // ---------------------------------------------------------------------------

  /// Navigate to the directory identified by [dirSegments] (name segments,
  /// without the leading separator).
  ///
  /// Returns `null` if any segment is missing or is not a directory.
  Future<OpfsDirectoryHandle?> _navigate(
    List<String> dirSegments, {
    bool create = false,
  }) async {
    var handle = await _rootHandle;
    for (final segment in dirSegments) {
      try {
        handle = await handle
            .getDirectoryHandle(
              segment,
              OpfsGetDirectoryOptions(create: create),
            )
            .toDart;
      } catch (_) {
        return null;
      }
    }
    return handle;
  }

  /// Type of the child named [name] in [parent], or `null` if not found.
  Future<fs.FileSystemEntityType?> _childType(
    OpfsDirectoryHandle parent,
    String name,
  ) async {
    try {
      await parent.getFileHandle(name).toDart;
      return fs.FileSystemEntityType.file;
    } catch (_) {}
    try {
      await parent.getDirectoryHandle(name).toDart;
      return fs.FileSystemEntityType.directory;
    } catch (_) {}
    return null;
  }

  /// Whether the directory [handle] has no children.
  Future<bool> _isEmpty(OpfsDirectoryHandle handle) async {
    await for (final _ in opfsListValues(handle)) {
      return false;
    }
    return true;
  }

  // ---------------------------------------------------------------------------
  // Operations
  // ---------------------------------------------------------------------------

  @override
  Future<fs.FileSystemEntityType> type(
    String path, {
    bool followLinks = true,
  }) async {
    final segments = opfsPathSegments(path);
    if (segments.isEmpty) {
      return fs.FileSystemEntityType.directory;
    }
    final parent = await _navigate(segments.sublist(0, segments.length - 1));
    if (parent == null) {
      return fs.FileSystemEntityType.notFound;
    }
    return (await _childType(parent, segments.last)) ??
        fs.FileSystemEntityType.notFound;
  }

  Future<bool> exists(String path) async =>
      (await type(path)) != fs.FileSystemEntityType.notFound;

  Future<OpfsFileStat> stat(String path) async {
    final stat = OpfsFileStat();
    final segments = opfsPathSegments(path);
    if (segments.isEmpty) {
      stat.type = fs.FileSystemEntityType.directory;
      return stat;
    }
    final parent = await _navigate(segments.sublist(0, segments.length - 1));
    if (parent == null) {
      stat.type = fs.FileSystemEntityType.notFound;
      return stat;
    }
    final name = segments.last;
    final type = await _childType(parent, name);
    if (type == null) {
      stat.type = fs.FileSystemEntityType.notFound;
    } else if (type == fs.FileSystemEntityType.file) {
      final handle = await parent.getFileHandle(name).toDart;
      final file = await handle.getFile().toDart;
      stat.type = type;
      stat.size = file.size;
      stat.modified = DateTime.fromMillisecondsSinceEpoch(
        file.lastModified.round(),
      );
    } else {
      stat.type = type;
      stat.size = 0;
    }
    return stat;
  }

  Future<void> createDirectory(String path, {bool recursive = false}) async {
    final segments = opfsPathSegments(path);
    if (segments.isEmpty) {
      // Root always exists.
      return;
    }
    final parentSegments = segments.sublist(0, segments.length - 1);
    final parent = await _navigate(parentSegments, create: recursive);
    if (parent == null) {
      throw opfsNotFoundException(path, 'Creation failed');
    }
    final name = segments.last;
    final existing = await _childType(parent, name);
    if (existing == fs.FileSystemEntityType.directory) {
      return;
    }
    if (existing == fs.FileSystemEntityType.file) {
      throw opfsAlreadyExistsException(path, 'Creation failed');
    }
    await parent
        .getDirectoryHandle(name, OpfsGetDirectoryOptions(create: true))
        .toDart;
  }

  Future<void> createFile(String path, {bool recursive = false}) async {
    final segments = opfsPathSegments(path);
    if (segments.isEmpty) {
      throw opfsIsADirectoryException(path, 'Creation failed');
    }
    final parentSegments = segments.sublist(0, segments.length - 1);
    final parent = await _navigate(parentSegments, create: recursive);
    if (parent == null) {
      throw opfsNotFoundException(path, 'Creation failed');
    }
    final name = segments.last;
    final existing = await _childType(parent, name);
    if (existing == fs.FileSystemEntityType.directory) {
      throw opfsIsADirectoryException(path, 'Creation failed');
    }
    if (existing == fs.FileSystemEntityType.file) {
      // Leave untouched.
      return;
    }
    await parent.getFileHandle(name, OpfsGetFileOptions(create: true)).toDart;
  }

  Future<void> delete(
    fs.FileSystemEntityType type,
    String path, {
    bool recursive = false,
  }) async {
    final segments = opfsPathSegments(path);
    if (segments.isEmpty) {
      throw opfsNotFoundException(path, 'Deletion failed');
    }
    final parentSegments = segments.sublist(0, segments.length - 1);
    final parent = await _navigate(parentSegments);
    if (parent == null) {
      throw opfsNotFoundException(path, 'Deletion failed');
    }
    final name = segments.last;
    final actual = await _childType(parent, name);
    if (actual == null) {
      throw opfsNotFoundException(path, 'Deletion failed');
    }
    if (actual != type) {
      if (actual == fs.FileSystemEntityType.directory) {
        throw opfsIsADirectoryException(path, 'Deletion failed');
      }
      throw opfsNotADirectoryException(path, 'Deletion failed');
    }
    if (actual == fs.FileSystemEntityType.directory && !recursive) {
      final dir = await parent.getDirectoryHandle(name).toDart;
      if (!await _isEmpty(dir)) {
        throw opfsNotEmptyException(path, 'Deletion failed');
      }
    }
    try {
      await parent
          .removeEntry(name, OpfsRemoveOptions(recursive: recursive))
          .toDart;
    } catch (e) {
      if (actual == fs.FileSystemEntityType.directory) {
        throw opfsNotEmptyException(path, 'Deletion failed');
      }
      rethrow;
    }
  }

  Future<void> rename(
    fs.FileSystemEntityType type,
    String path,
    String newPath,
  ) async {
    final segments = opfsPathSegments(path);
    final newSegments = opfsPathSegments(newPath);
    if (segments.isEmpty || newSegments.isEmpty) {
      throw opfsNotFoundException(path, 'Rename failed');
    }
    final parent = await _navigate(segments.sublist(0, segments.length - 1));
    if (parent == null) {
      throw opfsNotFoundException(path, 'Rename failed');
    }
    final name = segments.last;
    final actual = await _childType(parent, name);
    if (actual == null) {
      throw opfsNotFoundException(path, 'Rename failed');
    }

    final newParent = await _navigate(
      newSegments.sublist(0, newSegments.length - 1),
    );
    if (newParent == null) {
      throw opfsNotFoundException(path, 'Rename failed');
    }
    final newName = newSegments.last;
    final newActual = await _childType(newParent, newName);

    if (newActual != null) {
      if (newActual != actual) {
        if (actual == fs.FileSystemEntityType.directory) {
          throw opfsNotADirectoryException(path, 'Rename failed');
        }
        throw opfsIsADirectoryException(path, 'Rename failed');
      }
      if (newActual == fs.FileSystemEntityType.directory) {
        final dir = await newParent.getDirectoryHandle(newName).toDart;
        if (!await _isEmpty(dir)) {
          throw opfsNotEmptyException(path, 'Rename failed');
        }
        await newParent.removeEntry(newName).toDart;
      } else {
        await newParent.removeEntry(newName).toDart;
      }
    }

    if (actual == fs.FileSystemEntityType.file) {
      final src = await parent.getFileHandle(name).toDart;
      final dst = await newParent
          .getFileHandle(newName, OpfsGetFileOptions(create: true))
          .toDart;
      await opfsWriteFileHandle(dst, await opfsReadFileHandle(src));
      await parent.removeEntry(name).toDart;
    } else {
      final src = await parent.getDirectoryHandle(name).toDart;
      final dst = await newParent
          .getDirectoryHandle(newName, OpfsGetDirectoryOptions(create: true))
          .toDart;
      await _copyDirectoryInto(src, dst);
      await parent.removeEntry(name, OpfsRemoveOptions(recursive: true)).toDart;
    }
  }

  Future<void> _copyDirectoryInto(
    OpfsDirectoryHandle src,
    OpfsDirectoryHandle dst,
  ) async {
    final children = await opfsListValues(src).toList();
    for (final child in children) {
      final childName = child.name;
      if (child.kind == 'directory') {
        final srcChild = await src.getDirectoryHandle(childName).toDart;
        final dstChild = await dst
            .getDirectoryHandle(
              childName,
              OpfsGetDirectoryOptions(create: true),
            )
            .toDart;
        await _copyDirectoryInto(srcChild, dstChild);
      } else {
        final srcChild = await src.getFileHandle(childName).toDart;
        final dstChild = await dst
            .getFileHandle(childName, OpfsGetFileOptions(create: true))
            .toDart;
        await opfsWriteFileHandle(dstChild, await opfsReadFileHandle(srcChild));
      }
    }
  }

  Future<void> copyFile(fs.File file, String newPath) async {
    final segments = opfsPathSegments(file.path);
    final newSegments = opfsPathSegments(newPath);
    if (segments.isEmpty) {
      throw opfsNotFoundException(file.path, 'Copy failed');
    }
    final parent = await _navigate(segments.sublist(0, segments.length - 1));
    if (parent == null) {
      throw opfsNotFoundException(file.path, 'Copy failed');
    }
    final name = segments.last;
    final actual = await _childType(parent, name);
    if (actual == null) {
      throw opfsNotFoundException(file.path, 'Copy failed');
    }
    if (actual == fs.FileSystemEntityType.directory) {
      throw opfsIsADirectoryException(file.path, 'Copy failed');
    }

    final newParent = await _navigate(
      newSegments.sublist(0, newSegments.length - 1),
    );
    if (newParent == null) {
      throw opfsNotFoundException(file.path, 'Copy failed');
    }
    final newName = newSegments.last;
    final newActual = await _childType(newParent, newName);
    if (newActual == fs.FileSystemEntityType.directory) {
      throw opfsIsADirectoryException(file.path, 'Copy failed');
    }

    final src = await parent.getFileHandle(name).toDart;
    final dst = await newParent
        .getFileHandle(newName, OpfsGetFileOptions(create: true))
        .toDart;
    await opfsWriteFileHandle(dst, await opfsReadFileHandle(src));
  }

  /// Read all the bytes of an existing file.
  Future<Uint8List> readFileBytes(String path) async {
    final segments = opfsPathSegments(path);
    if (segments.isEmpty) {
      throw opfsIsADirectoryException(path, 'Read failed');
    }
    final parent = await _navigate(segments.sublist(0, segments.length - 1));
    if (parent == null) {
      throw opfsNotFoundException(path, 'Read failed');
    }
    final name = segments.last;
    final actual = await _childType(parent, name);
    if (actual == fs.FileSystemEntityType.directory) {
      throw opfsIsADirectoryException(path, 'Read failed');
    }
    if (actual == null) {
      throw opfsNotFoundException(path, 'Read failed');
    }
    final handle = await parent.getFileHandle(name).toDart;
    return opfsReadFileHandle(handle);
  }

  /// Write [bytes] to [path] following [mode] (write truncates, append adds).
  Future<void> writeFileBytes(
    String path,
    Uint8List bytes, {
    fs.FileMode mode = fs.FileMode.write,
  }) async {
    final segments = opfsPathSegments(path);
    if (segments.isEmpty) {
      throw opfsIsADirectoryException(path, 'Write failed');
    }
    final parent = await _navigate(segments.sublist(0, segments.length - 1));
    if (parent == null) {
      throw opfsNotFoundException(path, 'Write failed');
    }
    final name = segments.last;
    final actual = await _childType(parent, name);
    if (actual == fs.FileSystemEntityType.directory) {
      throw opfsIsADirectoryException(path, 'Write failed');
    }
    final handle = await parent
        .getFileHandle(name, OpfsGetFileOptions(create: true))
        .toDart;

    var content = bytes;
    if (mode == fs.FileMode.append) {
      final existing = await opfsReadFileHandle(handle);
      if (existing.isNotEmpty) {
        content = asUint8List([...existing, ...bytes]);
      }
    }
    await opfsWriteFileHandle(handle, content);
  }

  Stream<Uint8List> openRead(fs.File file, int? start, int? end) {
    final controller = StreamController<Uint8List>(sync: true);
    Future<void>(() async {
      try {
        var bytes = await readFileBytes(file.path);
        if (start != null || end != null) {
          final from = start ?? 0;
          final to = end ?? bytes.length;
          bytes = bytes.sublist(from, to > bytes.length ? bytes.length : to);
        }
        if (bytes.isNotEmpty) {
          controller.add(bytes);
        }
        await controller.close();
      } catch (e) {
        controller.addError(e);
        await controller.close();
      }
    });
    return controller.stream;
  }

  FileStreamSink openWrite(
    fs.File file, {
    fs.FileMode mode = fs.FileMode.write,
  }) {
    if (mode == fs.FileMode.read) {
      throw ArgumentError("Invalid file mode '$mode' for this operation");
    }
    return OpfsWriteStreamSink(this, file, mode);
  }

  Stream<OpfsFileSystemEntity> list(
    String path, {
    bool recursive = false,
    bool followLinks = true,
  }) {
    final controller = StreamController<OpfsFileSystemEntity>();

    Future<void> listInto(String dirPath, OpfsDirectoryHandle handle) async {
      final children = await opfsListValues(handle).toList();
      for (final child in children) {
        final childName = child.name;
        final childPath = opfsPathContext.join(dirPath, childName);
        if (child.kind == 'directory') {
          controller.add(OpfsDirectory(this, childPath));
          if (recursive) {
            final subHandle = await handle.getDirectoryHandle(childName).toDart;
            await listInto(childPath, subHandle);
          }
        } else {
          controller.add(OpfsFile(this, childPath));
        }
      }
    }

    Future<void>(() async {
      try {
        final segments = opfsPathSegments(path);
        final handle = await _navigate(segments);
        if (handle == null) {
          controller.addError(opfsNotFoundException(path, 'List failed'));
        } else {
          await listInto(path, handle);
        }
      } catch (e) {
        controller.addError(e);
      } finally {
        await controller.close();
      }
    });
    return controller.stream;
  }
}

/// Write sink buffering in memory, flushed to OPFS on close.
@visibleForTesting
class OpfsWriteStreamSink extends MemorySink {
  /// Write sink for [file] in [mode].
  OpfsWriteStreamSink(this._fs, this._file, this._mode);

  final FileSystemOpfsImpl _fs;
  final fs.File _file;
  final fs.FileMode _mode;

  @override
  Future<void> close() async {
    await super.close();
    await _fs.writeFileBytes(_file.path, asUint8List(content), mode: _mode);
  }
}
