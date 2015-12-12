library fs_shim.src.io.fs_io;

import '../../fs.dart' as fs;
export '../../fs.dart' show FileSystemEntityType;
import 'dart:io' as io;
import 'dart:async';
import 'io_fs.dart';

import '../../fs_io.dart';

class Link extends FileSystemEntity implements fs.Link {
  io.Link get ioLink => ioFileSystemEntity;

  Link _me(_) => this;

  Link._(io.Link dir) {
    ioFileSystemEntity = dir;
  }
  Link(String path) {
    ioFileSystemEntity = new io.Link(path);
  }

  @override
  Future<Link> create(String target, {bool recursive: false}) =>
      ioWrap(ioLink.create(target, recursive: recursive)).then(_me);

  @override
  Future<File> rename(String newPath) => ioWrap(ioLink.rename(newPath)).then(
      (io.FileSystemEntity ioFileSystemEntity) =>
          new File(ioFileSystemEntity.path));

  @override
  Link get absolute => new Link._(ioLink.absolute);
}
