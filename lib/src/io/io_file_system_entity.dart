library fs_shim.src.io.io_file_system_entity;

import '../../fs.dart' as fs;
export '../../fs.dart' show FileSystemEntityType;
import 'dart:io' as io;
import 'dart:async';
import 'io_fs.dart';
import '../../fs_io.dart';
import 'io_file_stat.dart';

abstract class FileSystemEntityImpl implements FileSystemEntity {
  io.FileSystemEntity ioFileSystemEntity;

  FileSystemEntity _me(_) => this;

  @override
  String get path => ioFileSystemEntity.path;

  @override
  String toString() => ioFileSystemEntity.toString();

  @override
  Future<bool> exists() => ioWrap(ioFileSystemEntity.exists()) as Future<bool>;

  @override
  Future<fs.FileSystemEntity> delete({bool recursive: false}) //
      =>
      ioWrap(ioFileSystemEntity.delete(recursive: recursive)).then(_me);

  @override
  bool get isAbsolute => ioFileSystemEntity.isAbsolute;

  @override
  Future<fs.FileStat> stat() => ioWrap(ioFileSystemEntity.stat())
      .then((io.FileStat stat) => new FileStatImpl(stat));
}
