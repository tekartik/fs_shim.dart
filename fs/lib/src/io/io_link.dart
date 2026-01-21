// ignore_for_file: public_member_api_docs

library;

import 'dart:io' as io;

import 'package:fs_shim/fs_io.dart';
import 'package:fs_shim/src/common/fs_mixin.dart';

import 'io_file_system_entity.dart';
import 'io_fs.dart';

class LinkImpl extends FileSystemEntityIoImpl
    with LinkMixin
    implements Link, FileSystemEntity {
  io.Link? get ioLink => ioFileSystemEntity as io.Link?;

  LinkImpl _me(_) => this;

  LinkImpl.io(io.Link dir) {
    ioFileSystemEntity = dir;
  }

  LinkImpl(String path) {
    ioFileSystemEntity = io.Link(path);
  }

  @override
  Future<LinkImpl> create(String target, {bool recursive = false}) =>
      ioWrap(ioLink!.create(target, recursive: recursive)).then(_me);

  @override
  Future<LinkImpl> rename(String newPath) =>
      ioWrap(ioLink!.rename(newPath)).then(
        (io.FileSystemEntity ioFileSystemEntity) =>
            LinkImpl(ioFileSystemEntity.path),
      );

  @override
  Future<String> target() => ioWrap(ioLink!.target());

  @override
  LinkImpl get absolute => LinkImpl.io(ioLink!.absolute);
}
