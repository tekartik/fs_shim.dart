library fs_shim.src.io.io_file_system_entity;

import 'dart:io' as io;
import 'dart:async';
import 'io_fs.dart';
import '../../fs_io.dart';
import 'io_file_stat.dart';
import 'io_directory.dart';

abstract class FileSystemEntityImpl implements FileSystemEntity {
  io.FileSystemEntity ioFileSystemEntity;

  FileSystemEntity _me(_) => this;

  @override
  IoFileSystem get fs => ioFileSystem;

  @override
  String get path => ioFileSystemEntity.path;

  @override
  String toString() => ioFileSystemEntity.toString();

  @override
  DirectoryImpl get parent => new DirectoryImpl.io(ioFileSystemEntity.parent);

  @override
  Future<bool> exists() => ioWrap(ioFileSystemEntity.exists()) as Future<bool>;

  @override
  Future<FileSystemEntity> delete({bool recursive: false}) //
      =>
      ioWrap(ioFileSystemEntity.delete(recursive: recursive)).then(_me);

  @override
  bool get isAbsolute => ioFileSystemEntity.isAbsolute;

  @override
  Future<FileStat> stat() => ioWrap(ioFileSystemEntity.stat())
      .then((io.FileStat stat) => new FileStatImpl(stat));
}
