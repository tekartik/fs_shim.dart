// ignore_for_file: public_member_api_docs

library fs_shim.src.io.io_file_system;

import 'dart:io' as io;

import 'package:fs_shim/fs.dart' as fs;
import 'package:fs_shim/fs_io.dart';
import 'package:fs_shim/src/common/fs_mixin.dart';
import 'package:path/path.dart';

import 'io_fs.dart';

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
  File file(String? path) => File(path!);

  @override
  Directory directory(String? path) => Directory(path!);

  @override
  Link link(String? path) => Link(path!);

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
}

/// File system
abstract class FileSystemIo extends fs.FileSystem {
  factory FileSystemIo() => IoFileSystemImpl();
}
