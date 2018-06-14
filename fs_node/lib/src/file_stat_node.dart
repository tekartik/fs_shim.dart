library fs_shim.src.io.io_file_stat;

import 'package:fs_shim/fs.dart';
import 'package:tekartik_fs_node/src/fs_node.dart';

import 'import_common_node.dart' as io;

// FileStat Wrap/unwrap
FileStatNode wrapIoFileStat(io.FileStat ioFileStat) =>
    ioFileStat != null ? new FileStatNode.io(ioFileStat) : null;
io.FileStat unwrapIoFileStat(FileStat fileStat) =>
    fileStat != null ? (fileStat as FileStatNode).ioFileStat : null;

class FileStatNode implements FileStat {
  FileStatNode.io(this.ioFileStat);

  io.FileStat ioFileStat;

  @override
  DateTime get modified => ioFileStat.modified;

  @override
  int get size => ioFileStat.size;

  @override
  FileSystemEntityType get type =>
      wrapIoFileSystemEntityTypeImpl(ioFileStat.type);

  @override
  String toString() => ioFileStat.toString();
}
