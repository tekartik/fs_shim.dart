library fs_shim.src.io.io_file_stat;

import '../../fs.dart' as fs;
export '../../fs.dart' show FileSystemEntityType;
import 'dart:io' as io;
import 'io_fs.dart';
import '../../fs_io.dart';

class FileStatImpl implements FileStat {
  FileStatImpl(this.ioFileStat);
  io.FileStat ioFileStat;

  @override
  DateTime get modified => ioFileStat.modified;

  @override
  int get size => ioFileStat.size;

  @override
  fs.FileSystemEntityType get type => ioFsFileType(ioFileStat.type);

  @override
  String toString() => ioFileStat.toString();
}
