// ignore_for_file: public_member_api_docs

import 'dart:typed_data';

import 'package:fs_shim/fs.dart' as fs;
import 'package:fs_shim/src/common/fs_mixin.dart';

import '../../fs.dart';
import 'idb_file_system_entity.dart';
import 'idb_fs.dart';

class IdbFile extends IdbFileSystemEntity with FileMixin implements fs.File {
  IdbFile(super.fs, super.path);

  IdbFileSystem get _fs => super.fs;

  @override
  Future<IdbFile> create({bool recursive = false}) {
    return _fs.createFile(path, recursive: recursive).then((_) => this);
  }

  @override
  fs.FileSystemEntityType get type => fs.FileSystemEntityType.file;

  // don't care about encoding - assume UTF8
  @override
  StreamSink<List<int>> openWrite({
    fs.FileMode mode = fs.FileMode.write,
    Encoding encoding = utf8,
  }) //
  => _fs.openWrite(this, mode: mode);

  @override
  Stream<Uint8List> openRead([int? start, int? end]) =>
      _fs.openRead(this, start, end);

  @override
  Future<RandomAccessFile> open({FileMode mode = FileMode.read}) =>
      _fs.open(this, mode: mode);

  @override
  Future<IdbFile> rename(String newPath) {
    return _fs.rename(type, path, newPath).then((_) => IdbFile(_fs, newPath));
  }

  @override
  Future<IdbFile> copy(String newPath) {
    return _fs.copyFile(this, newPath).then((_) => IdbFile(_fs, newPath));
  }

  @override
  IdbFile get absolute => IdbFile(_fs, idbMakePathAbsolute(path));

  @override
  String toString() => "File: '$path'";
}
