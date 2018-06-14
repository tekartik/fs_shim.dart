library fs_shim.src.io.io_file_system_entity;

import 'dart:async';
import 'dart:io' as io;

import '../../fs_io.dart';
import 'io_directory.dart';
import 'io_file_stat.dart';
import 'io_fs.dart';

abstract class FileSystemEntityImpl implements FileSystemEntity {
  io.FileSystemEntity ioFileSystemEntity;

  FileSystemEntity _me(_) => this;

  @override
  IoFileSystem get fs => ioFileSystem as IoFileSystem;

  @override
  String get path => ioFileSystemEntity.path;

  @override
  String toString() => ioFileSystemEntity.toString();

  @override
  DirectoryImpl get parent => new DirectoryImpl.io(ioFileSystemEntity.parent);

  @override
  Future<bool> exists() => ioWrap(ioFileSystemEntity.exists());

  @override
  Future<FileSystemEntity> delete({bool recursive: false}) //
      =>
      ioWrap(ioFileSystemEntity.delete(recursive: recursive)).then(_me);

  @override
  bool get isAbsolute => ioFileSystemEntity.isAbsolute;

  @override
  Future<FileStat> stat() => ioWrap(ioFileSystemEntity.stat())
      .then((io.FileStat stat) => new FileStatImpl.io(stat));
}
