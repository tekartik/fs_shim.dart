library fs_shim.src.io.io_link;

export '../../fs.dart' show FileSystemEntityType;
import 'dart:io' as io;
import 'dart:async';
import 'io_fs.dart';
import 'io_file_system_entity.dart';
import '../../fs_io.dart';

class LinkImpl extends FileSystemEntityImpl implements Link {
  io.Link get ioLink => ioFileSystemEntity;

  LinkImpl _me(_) => this;

  LinkImpl.io(io.Link dir) {
    ioFileSystemEntity = dir;
  }
  LinkImpl(String path) {
    ioFileSystemEntity = new io.Link(path);
  }

  @override
  Future<LinkImpl> create(String target, {bool recursive: false}) =>
      ioWrap(ioLink.create(target, recursive: recursive)).then(_me);

  @override
  Future<LinkImpl> rename(String newPath) => ioWrap(ioLink.rename(newPath))
      .then((io.FileSystemEntity ioFileSystemEntity) =>
          new LinkImpl(ioFileSystemEntity.path));

  @override
  Future<String> target() => ioWrap(ioLink.target()) as Future<String>;

  @override
  LinkImpl get absolute => new LinkImpl.io(ioLink.absolute);
}
