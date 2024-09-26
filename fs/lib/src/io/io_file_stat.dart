// ignore_for_file: public_member_api_docs

library;

import 'dart:io' as io;

import 'package:fs_shim/fs.dart' as fs;
import 'package:fs_shim/fs_io.dart';
import 'package:fs_shim/src/common/fs_mixin.dart';

import 'io_fs.dart';

class FileStatImpl extends Object with FileStatModeMixin implements FileStat {
  FileStatImpl.io(this.ioFileStat);

  io.FileStat ioFileStat;

  @override
  DateTime get modified => ioFileStat.modified;

  @override
  int get size => ioFileStat.size;

  @override
  fs.FileSystemEntityType get type =>
      wrapIoFileSystemEntityTypeImpl(ioFileStat.type);

  @override
  String toString() => ioFileStat.toString();

  @override
  int get mode => ioFileStat.mode;
}
