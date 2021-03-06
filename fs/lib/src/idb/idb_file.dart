import 'dart:typed_data';

import 'package:fs_shim/fs.dart' as fs;
import 'package:fs_shim/src/common/fs_mixin.dart';

import 'idb_file_system_entity.dart';
import 'idb_fs.dart';

class IdbFile extends IdbFileSystemEntity with FileMixin implements fs.File {
  IdbFile(IdbFileSystem fs, String? path) : super(fs, path);

  IdbFileSystem get _fs => super.fs;

  @override
  Future<IdbFile> create({bool recursive = false}) {
    return _fs.createFile(path, recursive: recursive).then((_) => this);
  }

  @override
  fs.FileSystemEntityType get type => fs.FileSystemEntityType.file;

  // don't care about encoding - assume UTF8
  @override
  StreamSink<List<int>> openWrite(
          {fs.FileMode mode = fs.FileMode.write, Encoding encoding = utf8}) //
      =>
      _fs.openWrite(path, mode: mode);

  @override
  Stream<Uint8List> openRead([int? start, int? end]) =>
      _fs.openRead(path, start, end);

  @override
  Future<IdbFile> rename(String newPath) {
    return _fs.rename(type, path, newPath).then((_) => IdbFile(_fs, newPath));
  }

  @override
  Future<IdbFile> copy(String newPath) {
    return _fs.copyFile(path, newPath).then((_) => IdbFile(_fs, newPath));
  }

  @override
  Future<IdbFile> writeAsBytes(Uint8List bytes,
          {fs.FileMode mode = fs.FileMode.write, bool flush = false}) async =>
      await doWriteAsBytes(bytes, mode: mode, flush: flush) as IdbFile;

  @override
  Future<IdbFile> writeAsString(String contents,
          {fs.FileMode mode = fs.FileMode.write,
          Encoding encoding = utf8,
          bool flush = false}) async =>
      await doWriteAsString(contents,
          mode: mode, encoding: encoding, flush: flush) as IdbFile;

  @override
  IdbFile get absolute => IdbFile(_fs, idbMakePathAbsolute(path));

  @override
  String toString() => "File: '$path'";
}
