// ignore_for_file: public_member_api_docs

library fs_shim.src.io.io_file_system;

import 'dart:io' as io;

import 'package:fs_shim/fs.dart' as fs;
import 'package:fs_shim/src/common/fs_mixin.dart';
import 'package:fs_shim/src/io/io_directory.dart';
import 'package:path/path.dart';

import 'io_file.dart';
import 'io_fs.dart';
import 'io_link.dart';

export 'package:fs_shim/fs.dart' show FileSystemEntityType;

class IoFileSystemImpl extends Object
    with FileSystemMixin
    implements FileSystemIo {
  @override
  Future<fs.FileSystemEntityType> type(String? path,
          {bool followLinks = true}) async =>
      wrapIoFileSystemEntityTypeImpl(
          io.FileSystemEntity.typeSync(path!, followLinks: followLinks));

  @override
  fs.File file(String? path) => FileImpl(path!);

  @override
  fs.Directory directory(String? path) => DirectoryImpl(path!);

  @override
  fs.Link link(String? path) => LinkImpl(path!);

  @override
  String get name => 'io';

  @override
  bool get supportsLink => true;

  @override
  bool get supportsFileLink => !io.Platform.isWindows;

  @override
  String toString() => name;

  @override
  int get hashCode => name.hashCode;

  @override
  bool operator ==(Object other) {
    return other is IoFileSystemImpl;
  }

  @override
  Context get pathContext => path;

  @override
  Context get path => context;

  @override
  Future<bool> isLink(String? path) =>
      Future.value(io.FileSystemEntity.isLinkSync(path!));

  @override
  Future<bool> isFile(String? path) =>
      Future.value(io.FileSystemEntity.isFileSync(path!));

  @override
  Future<bool> isDirectory(String? path) =>
      Future.value(io.FileSystemEntity.isDirectorySync(path!));

  @override
  bool get supportsRandomAccess => true;

  @override
  fs.Directory get currentDirectory => currentDirectoryIo;
}

/// File system
abstract class FileSystemIo extends fs.FileSystem {
  factory FileSystemIo() => IoFileSystemImpl();
}
