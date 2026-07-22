// ignore_for_file: public_member_api_docs

import 'dart:convert';
import 'dart:typed_data';

import 'package:fs_shim/fs.dart' as fs;
import 'package:fs_shim/src/common/fs_mixin.dart';

import '../../fs.dart';
import 'opfs_file_system.dart';
import 'opfs_file_system_entity.dart';
import 'opfs_fs.dart';

/// OpfsFile representation.
class OpfsFile extends OpfsFileSystemEntity with FileMixin implements fs.File {
  OpfsFile(super.fs, super.path);

  FileSystemOpfsImpl get _fs => super.fs;

  @override
  fs.FileSystemEntityType get type => fs.FileSystemEntityType.file;

  @override
  Future<OpfsFile> create({bool recursive = false}) =>
      _fs.createFile(path, recursive: recursive).then((_) => this);

  @override
  FileStreamSink openWrite({
    fs.FileMode mode = fs.FileMode.write,
    Encoding encoding = utf8,
  }) => _fs.openWrite(this, mode: mode);

  @override
  Stream<Uint8List> openRead([int? start, int? end]) =>
      _fs.openRead(this, start, end);

  @override
  Future<OpfsFile> rename(String newPath) =>
      _fs.rename(type, path, newPath).then((_) => OpfsFile(_fs, newPath));

  @override
  Future<OpfsFile> copy(String newPath) =>
      _fs.copyFile(this, newPath).then((_) => OpfsFile(_fs, newPath));

  @override
  OpfsFile get absolute => OpfsFile(_fs, opfsMakePathAbsolute(path));

  @override
  String toString() => "File: '$path'";
}
