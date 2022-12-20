// ignore_for_file: public_member_api_docs

import 'package:fs_shim/src/common/import.dart';

mixin FileSystemEntityMixin implements FileSystemEntity {
  @override
  Future<FileSystemEntity> delete({bool recursive = false}) =>
      throw UnsupportedError('fse.delete');

  @override
  Future<bool> exists() => throw UnsupportedError('fse.exists');

  @override
  bool get isAbsolute => throw UnsupportedError('fse.isAbsolute');

  @override
  Directory get parent => throw UnsupportedError('fse.parent');

  @override
  String get path => throw UnsupportedError('fse.path');

  @override
  Future<FileSystemEntity> rename(String newPath) =>
      throw UnsupportedError('fse.rename');

  @override
  Future<FileStat> stat() => throw UnsupportedError('fse.stat');

  @override
  FileSystem get fs => throw UnsupportedError('fse.fs');
}

abstract class DirectoryNone implements Directory {
  @override
  Directory get absolute => throw UnsupportedError('directory.absolute');

  @override
  Future<Directory> create({bool recursive = false}) =>
      throw UnsupportedError('directory.create');

  @override
  Stream<FileSystemEntity> list(
          {bool recursive = false, bool followLinks = true}) =>
      throw UnsupportedError('directory.list');
}
