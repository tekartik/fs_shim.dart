// ignore_for_file: public_member_api_docs

import 'package:fs_shim/fs.dart' as fs;
import 'package:fs_shim/fs.dart' show FileStat, FileSystemEntityType;

import 'opfs_directory.dart';
import 'opfs_file_system.dart';
import 'opfs_fs.dart';

abstract class OpfsFileSystemEntity implements fs.FileSystemEntity {
  OpfsFileSystemEntity(this._fs, this._path);

  final FileSystemOpfsImpl _fs;

  @override
  FileSystemOpfsImpl get fs => _fs;

  final String _path;

  @override
  String get path => _path;

  /// Subclass type.
  FileSystemEntityType get type;

  @override
  OpfsDirectory get parent =>
      _fs.directory(opfsPathContext.dirname(path)) as OpfsDirectory;

  @override
  Future<OpfsFileSystemEntity> delete({bool recursive = false}) =>
      _fs.delete(type, path, recursive: recursive).then((_) => this);

  @override
  Future<bool> exists() => _fs.exists(path);

  @override
  Future<FileStat> stat() => _fs.stat(path);

  @override
  bool get isAbsolute => opfsPathContext.isAbsolute(path);

  @override
  String toString() => path;
}
