// ignore_for_file: public_member_api_docs

import 'package:fs_shim/fs.dart' as fs;
import 'package:fs_shim/fs.dart' show FileSystemEntityType, FileStat;
import 'package:path/path.dart' as path_pkg;

import 'idb_directory.dart';
import 'idb_fs.dart';

abstract class IdbFileSystemEntity implements fs.FileSystemEntity {
  final IdbFileSystem _fs;

  @override
  IdbFileSystem get fs => _fs;

  final String? _path;

  @override
  String get path => _path!;

  // subclass type
  FileSystemEntityType get type;

  @override
  IdbDirectory get parent => fs.directory(path_pkg.dirname(path));

  IdbFileSystemEntity(this._fs, this._path);

  @override
  Future<IdbFileSystemEntity> delete({bool recursive = false}) {
    return _fs.delete(type, path, recursive: recursive).then((_) => this);
  }

  @override
  Future<bool> exists() {
    return _fs.exists(path);
  }

  @override
  Future<FileStat> stat() {
    return _fs.stat(path);
  }

  @override
  bool get isAbsolute => path_pkg.isAbsolute(path);

  // don't care about recursive
  //@override
  //Future<fs.FileSystemEntity> delete({bool recursive: false}) async {
  //    _fs._impl.delete(path, recursive: recursive);
  //    return this;
  //  }

  @override
  String toString() => path;
}
