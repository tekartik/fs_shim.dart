// ignore_for_file: public_member_api_docs

import 'package:fs_shim/fs.dart' as fs;

import 'idb_file_system_entity.dart';
import 'idb_fs.dart';

class IdbDirectory extends IdbFileSystemEntity implements fs.Directory {
  IdbDirectory(IdbFileSystem fs, String? path) : super(fs, path);

  IdbDirectory _me(_) => this;

  @override
  Future<IdbDirectory> create({bool recursive = false}) =>
      super.fs.createDirectory(path, recursive: recursive).then(_me);

  @override
  fs.FileSystemEntityType get type => fs.FileSystemEntityType.directory;

  @override
  Future<IdbDirectory> rename(String newPath) {
    return super
        .fs
        .rename(type, path, newPath)
        .then((_) => IdbDirectory(super.fs, newPath));
  }

  @override
  Stream<IdbFileSystemEntity> list(
          {bool recursive = false, bool followLinks = true}) =>
      super.fs.list(path, recursive: recursive, followLinks: followLinks);

  @override
  IdbDirectory get absolute =>
      IdbDirectory(super.fs, idbMakePathAbsolute(path));

  @override
  String toString() => "Directory: '$path'";
}
