library fs_shim.src.io.io_file_stat;

import 'dart:io' as io;

import 'package:fs_shim/fs.dart' as fs;
import 'package:fs_shim/fs_io.dart';

import 'io_fs.dart';

export 'package:fs_shim/fs.dart' show FileSystemEntityType;

class FileStatImpl implements FileStat {
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
}
