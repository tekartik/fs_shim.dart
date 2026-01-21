import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:fs_shim/fs.dart';
import 'package:fs_shim/fs_mixin.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart';

import 'package:path/path.dart' as path_prefix;

/// A file system that is sandboxed to a specific directory.
abstract class FsShimSandboxedFileSystem implements FileSystem {
  /// The root directory of the sandbox, absolute and normalized in the delegate file system.
  Directory get rootDirectory;

  /// Converts a path in the sandboxed file system to a path in the delegate file system.
  String delegatePath(String path);

  /// Converts a path in the delegate file system to a path in the sandboxed file system.
  /// throws a PathException if the path is outside the sandbox.
  String sandboxPath(String path);
}

abstract class _SandboxFileSystemEntity with FileSystemEntityMixin {
  late final String delegatePath = fs.delegatePath(path);
  FileSystemEntity get _entityDelegate;

  path_prefix.Context get p => fs.p;
  @override
  final _SandboxedFileSystem fs;
  @override
  final String path;

  String get absolutePath => fs.absolutePath(path);

  @override
  Future<FileSystemEntity> delete({bool recursive = false}) async {
    await _entityDelegate.delete(recursive: recursive);
    return this;
  }

  _SandboxFileSystemEntity({required this.fs, required this.path});

  @override
  Future<bool> exists() => _entityDelegate.exists();

  @override
  Future<FileStat> stat() => _entityDelegate.stat();
}

class _SandboxFile extends _SandboxFileSystemEntity with FileMixin {
  _SandboxFile({required super.fs, required super.path});
  late final _fileDelegate = fs._fsDelegate.file(delegatePath);

  @override
  Stream<Uint8List> openRead([int? start, int? end]) =>
      _fileDelegate.openRead(start, end);

  @override
  StreamSink<List<int>> openWrite({
    FileMode mode = FileMode.write,
    Encoding encoding = utf8,
  }) => _fileDelegate.openWrite(mode: mode, encoding: encoding);

  @override
  Future<File> create({bool recursive = false}) =>
      _fileDelegate.create(recursive: recursive);

  @override
  FileSystemEntity get _entityDelegate => _fileDelegate;

  @override
  Future<_SandboxFile> rename(String newPath) async {
    await _entityDelegate.rename(fs.delegatePath(newPath));
    return _SandboxFile(fs: fs, path: newPath);
  }

  @override
  File get absolute {
    if (p.isAbsolute(path)) {
      return this;
    } else {
      return fs.file(absolutePath);
    }
  }

  @override
  Future<File> copy(String newPath) async {
    await _fileDelegate.copy(fs.delegatePath(newPath));
    return _SandboxFile(fs: fs, path: newPath);
  }
}

class _SandboxDirectory extends _SandboxFileSystemEntity with DirectoryMixin {
  _SandboxDirectory({required super.fs, required super.path});
  late final _directoryDelegate = fs._fsDelegate.directory(delegatePath);
  @override
  FileSystemEntity get _entityDelegate => _directoryDelegate;
  @override
  Directory get absolute {
    if (p.isAbsolute(path)) {
      return this;
    } else {
      return fs.directory(absolutePath);
    }
  }

  @override
  Future<Directory> create({bool recursive = false}) async {
    await _directoryDelegate.create(recursive: recursive);
    return this;
  }

  @override
  Future<_SandboxDirectory> rename(String newPath) async {
    await _directoryDelegate.rename(fs.delegatePath(newPath));
    return _SandboxDirectory(fs: fs, path: newPath);
  }

  FileSystemEntity _fixListEntity(FileSystemEntity entity) {
    String path;
    if (fs.path.isAbsolute(entity.path)) {
      // throw UnsupportedError('Entity path is absolute: ${entity.path}');
      path = p.join(
        p.separator,
        p.relative(entity.path, from: fs.rootDirectory.path),
      );
    } else {
      path = p.join(this.path, entity.path);
    }
    if (entity is File) {
      return fs.file(path);
    } else if (entity is Directory) {
      return fs.directory(path);
    } else if (entity is Link) {
      return fs.link(path);
    } else {
      throw UnsupportedError('Unsupported entity type: $entity');
    }
  }

  @override
  Stream<FileSystemEntity> list({
    bool recursive = false,
    bool followLinks = true,
  }) => _directoryDelegate
      .list(recursive: recursive, followLinks: followLinks)
      .map((entity) {
        var fixedEntity = _fixListEntity(entity);
        return fixedEntity;
      });
}

class _SandboxLink extends _SandboxFileSystemEntity with LinkMixin {
  _SandboxLink({required super.fs, required super.path});
  late final _linkDelegate = fs._fsDelegate.link(delegatePath);
  @override
  FileSystemEntity get _entityDelegate => _linkDelegate;

  @override
  Future<_SandboxLink> rename(String newPath) async {
    await _linkDelegate.rename(fs.delegatePath(newPath));
    return _SandboxLink(fs: fs, path: newPath);
  }

  @override
  Link get absolute {
    if (p.isAbsolute(path)) {
      return this;
    } else {
      return fs.link(absolutePath);
    }
  }

  @override
  Future<Link> create(String target, {bool recursive = false}) async {
    if (p.isRelative(target)) {
      var delegatePath = fs.delegatePath(p.join(p.dirname(path), target));
      await _linkDelegate.create(delegatePath, recursive: recursive);
      return this;
    }
    await _linkDelegate.create(fs.delegatePath(target), recursive: recursive);
    return this;
  }

  @override
  Future<String> target() async {
    var targetDelegatePath = await _linkDelegate.target();
    var sandboxPath = fs.sandboxPath(targetDelegatePath);
    return sandboxPath;
  }
}

@internal
abstract class FsShimSandboxedFileSystemImpl extends FsShimSandboxedFileSystem {
  factory FsShimSandboxedFileSystemImpl({required Directory rootDirectory}) =>
      _SandboxedFileSystem(rootDirectory: rootDirectory);
}

class _SandboxedFileSystem
    with FileSystemMixin
    implements FsShimSandboxedFileSystemImpl {
  late final FileSystem _fsDelegate = rootDirectory.fs;

  /// The root directory of the sandbox in the delegate file system.
  @override
  final Directory rootDirectory;

  _SandboxedFileSystem({required this.rootDirectory}) {
    assert(rootDirectory.isAbsolute);
  }

  path_prefix.Context get p => _fsDelegate.path;
  @override
  path_prefix.Context get path => p;

  @override
  String sandboxPath(String path) {
    var relativePath = p.relative(path, from: rootDirectory.path);
    if (relativePath.startsWith('..')) {
      throw PathException(
        'Path $path is outside of the sandbox root ${rootDirectory.path}',
      );
    }
    if (p.isAbsolute(relativePath)) {
      throw StateError('Relative path is absolute: $relativePath');
      // return p.join(p.separator, relativePath);
    } else {
      return join(p.separator, relativePath);
    }
  }

  @override
  bool get supportsLink => _fsDelegate.supportsLink;

  @override
  bool get supportsFileLink => _fsDelegate.supportsFileLink;

  @override
  Directory get currentDirectory => directory(p.separator);

  @override
  String delegatePath(String path) {
    var sep = p.separator;
    String rawPath;
    if (p.isAbsolute(path)) {
      var relativePath = p.relative(path, from: sep);
      rawPath = p.join(rootDirectory.path, relativePath);
    } else {
      rawPath = p.join(rootDirectory.path, path);
    }
    var normalizedPath = p.normalize(rawPath);
    return normalizedPath;
  }

  @override
  Future<FileSystemEntityType> type(String path, {bool followLinks = true}) =>
      _fsDelegate.type(delegatePath(path), followLinks: followLinks);
  @override
  File file(String path) => _SandboxFile(fs: this, path: path);

  @override
  Directory directory(String path) => _SandboxDirectory(fs: this, path: path);

  @override
  Link link(String path) => _SandboxLink(fs: this, path: path);

  @override
  String get name => 'sandbox(${_fsDelegate.name}, ${rootDirectory.path})';
}
