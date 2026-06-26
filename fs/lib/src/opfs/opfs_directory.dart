// ignore_for_file: public_member_api_docs

import 'package:fs_shim/fs.dart' as fs;
import 'package:fs_shim/fs_mixin.dart';

import 'opfs_file_system.dart';
import 'opfs_file_system_entity.dart';
import 'opfs_fs.dart';

class OpfsDirectory extends OpfsFileSystemEntity
    with DirectoryMixin
    implements fs.Directory {
  OpfsDirectory(super.fs, super.path);

  FileSystemOpfsImpl get _fs => super.fs;

  OpfsDirectory _me(_) => this;

  @override
  fs.FileSystemEntityType get type => fs.FileSystemEntityType.directory;

  @override
  Future<OpfsDirectory> create({bool recursive = false}) =>
      _fs.createDirectory(path, recursive: recursive).then(_me);

  @override
  Future<OpfsDirectory> rename(String newPath) =>
      _fs.rename(type, path, newPath).then((_) => OpfsDirectory(_fs, newPath));

  @override
  Stream<OpfsFileSystemEntity> list({
    bool recursive = false,
    bool followLinks = true,
  }) => _fs.list(path, recursive: recursive, followLinks: followLinks);

  @override
  OpfsDirectory get absolute => OpfsDirectory(_fs, opfsMakePathAbsolute(path));

  @override
  String toString() => "Directory: '$path'";
}
