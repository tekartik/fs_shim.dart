library fs_shim.src.io.io_file_system;

import '../../fs.dart' as fs;
export '../../fs.dart' show FileSystemEntityType;
import 'dart:io' as io;
import 'dart:async';
import 'io_fs.dart';
import '../../src/common/fs_mixin.dart';
import '../../fs_io.dart';

class IoFileSystemImpl extends Object
    with FileSystemMixin
    implements IoFileSystem {
  @override
  Future<fs.FileSystemEntityType> type(String path, {bool followLinks: true}) //
      =>
      ioWrap(io.FileSystemEntity.type(path, followLinks: followLinks))
          .then((io.FileSystemEntityType ioType) => ioFsFileType(ioType));

  @override
  File newFile(String path) => new File(path);

  @override
  Directory newDirectory(String path) => new Directory(path);

  @override
  Link newLink(String path) => new Link(path);

  @override
  String get name => 'io';
  @override
  bool get supportsLink => true;
}
