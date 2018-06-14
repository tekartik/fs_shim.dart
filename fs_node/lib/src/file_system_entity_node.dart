import 'dart:async';
import 'package:fs_shim/fs.dart';
import 'package:tekartik_fs_node/src/file_stat_node.dart';
import 'import_common_node.dart' as io;
import 'package:tekartik_fs_node/src/directory_node.dart';
import 'package:tekartik_fs_node/src/file_system_node.dart';
import 'package:tekartik_fs_node/src/fs_node.dart';

abstract class FileSystemEntityNode implements FileSystemEntity {
  final io.FileSystemEntity nativeInstance;

  FileSystemEntityNode(this.nativeInstance);

  FileSystemEntity _me(_) => this;

  @override
  FileSystemNode get fs => fileSystemNode;

  @override
  String get path => nativeInstance.path;

  @override
  String toString() => nativeInstance.toString();

  @override
  DirectoryNode get parent => new DirectoryNode(nativeInstance.parent.path);

  @override
  Future<bool> exists() => ioWrap(nativeInstance.exists());

  @override
  Future<FileSystemEntity> delete({bool recursive: false}) //
      =>
      ioWrap(nativeInstance.delete(recursive: recursive)).then(_me);

  @override
  bool get isAbsolute => nativeInstance.isAbsolute;

  @override
  Future<FileStat> stat() async {
    var stat = await ioWrap(nativeInstance.stat());
    return new FileStatNode.io(stat);
  }
}
