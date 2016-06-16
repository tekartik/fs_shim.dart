library fs_shim.src.idb.idb_file_system_entity;

import 'idb_fs.dart';
import '../../fs.dart' as fs;
import 'package:path/path.dart' as path_pkg;
import 'idb_directory.dart';

abstract class IdbFileSystemEntity implements fs.FileSystemEntity {
  IdbFileSystem _fs;

  @override
  IdbFileSystem get fs => _fs;

  final String _path;

  @override
  String get path => _path;

  // subclass type
  fs.FileSystemEntityType get type;

  @override
  IdbDirectory get parent => fs.newDirectory(path_pkg.dirname(path));

  IdbFileSystemEntity(this._fs, this._path) {
    if (path == null) {
      throw new ArgumentError.notNull("path");
    }
  }

  Future<IdbFileSystemEntity> delete({bool recursive: false}) {
    return _fs.delete(type, path, recursive: recursive).then((_) => this);
  }

  @override
  Future<bool> exists() {
    return _fs.exists(path);
  }

  @override
  Future<fs.FileStat> stat() {
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
