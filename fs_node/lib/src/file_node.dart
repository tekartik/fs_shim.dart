import 'dart:async';
import 'package:fs_shim/fs.dart';
import 'package:tekartik_fs_node/src/file_system_entity_node.dart';
import 'package:tekartik_fs_node/src/fs_node.dart';

import 'import_common_node.dart' as io;

Future<File> _wrapFutureFile(Future<File> future) => ioWrap(future);

Future<String> _wrapFutureString(Future<String> future) => ioWrap(future);

// Wrap/unwrap
FileNode wrapIoFile(io.File ioFile) =>
    ioFile != null ? new FileNode.io(ioFile) : null;

io.File unwrapIoFile(File file) =>
    file != null ? (file as FileNode).ioFile : null;

class FileNode extends FileSystemEntityNode implements File {
  io.File get ioFile => nativeInstance as io.File;

  FileNode.io(io.File file) : super(file);

  FileNode(String path) : super(new io.File(path));

  @override
  Future<FileNode> create({bool recursive: false}) //
      =>
      ioWrap(ioFile.create(recursive: recursive)).then(_me);

  // ioFile.openWrite(mode: _fileMode(mode), encoding: encoding);
  @override
  StreamSink<List<int>> openWrite(
      {FileMode mode: FileMode.write, Encoding encoding: utf8}) {
    IoWriteFileSink sink = new IoWriteFileSink(
        ioFile.openWrite(mode: fileWriteMode(mode), encoding: encoding));
    return sink;
  }

  FileNode _me(_) => this;

  @override
  Stream<List<int>> openRead([int start, int end]) {
    return new IoReadFileStreamCtrl(ioFile.openRead(start, end)).stream;
  }

  @override
  Future<FileNode> rename(String newPath) => _wrapFutureFile(ioFile
      .rename(newPath)
      .then((io.FileSystemEntity ioFileSystemEntity) =>
          new FileNode(ioFileSystemEntity.path))) as Future<FileNode>;

  @override
  Future<FileNode> copy(String newPath) => _wrapFutureFile(ioFile
      .copy(newPath)
      .then((io.FileSystemEntity ioFileSystemEntity) =>
          new FileNode(ioFileSystemEntity.path))) as Future<FileNode>;

  @override
  Future<FileNode> writeAsBytes(List<int> bytes,
          {FileMode mode: FileMode.write, bool flush: false}) =>
      ioWrap(ioFile.writeAsBytes(bytes,
              mode: fileWriteMode(mode), flush: flush))
          .then(_me);

  @override
  Future<FileNode> writeAsString(String contents,
          {FileMode mode: FileMode.write,
          Encoding encoding: utf8,
          bool flush: false}) =>
      ioWrap(ioFile.writeAsString(contents,
              mode: fileWriteMode(mode), encoding: encoding, flush: flush))
          .then(_me);

  @override
  Future<List<int>> readAsBytes() => ioWrap(ioFile.readAsBytes());

  @override
  Future<String> readAsString({Encoding encoding: utf8}) =>
      _wrapFutureString(ioFile.readAsString(encoding: encoding));

  @override
  File get absolute => new FileNode.io(ioFile.absolute);
}
