import 'dart:async';
import 'dart:convert';
import 'dart:io' as vm_io;
import 'dart:typed_data';

import 'package:fs_shim/fs.dart';
import 'package:tekartik_fs_node/src/file_system_entity_node.dart';
import 'package:tekartik_fs_node/src/fs_node.dart';
import 'package:tekartik_fs_node/src/import_common.dart';

import 'package:fs_shim/src/common/compat.dart'; // ignore: implementation_imports

import 'import_common_node.dart' as io;

Future<String> _wrapFutureString(Future<String> future) => ioWrap(future);

// Wrap/unwrap
FileNode wrapIoFile(vm_io.File ioFile) =>
    ioFile != null ? FileNode.io(ioFile) : null;

vm_io.File unwrapIoFile(File file) =>
    file != null ? (file as FileNode).ioFile : null;

class FileNode extends FileSystemEntityNode implements File {
  FileNode.io(vm_io.File file) : super(file);

  FileNode(String path) : super(io.File(path));

  vm_io.File get ioFile => nativeInstance as io.File;

  @override
  Future<FileNode> create({bool recursive = false}) async {
    recursive ??= false;
    if (await exists()) {
      await delete();
    }
    if (recursive) {
      await pathRecursiveCreateParent(path);
    }
    await ioWrap(ioFile.create(recursive: false));

    return this;
  }

  @override
  Future<FileNode> delete({bool recursive = false}) async {
    // if recursive is true, delete whetever types it is per definition
    if (recursive) {
      await fsNode.deleteAny(path);
      return this;
    }
    await super.delete();
    return this;
  }

  // ioFile.openWrite(mode: _fileMode(mode), encoding: encoding);
  @override
  StreamSink<List<int>> openWrite(
      {FileMode mode = FileMode.write, Encoding encoding = utf8}) {
    if (mode == FileMode.read) {
      throw ArgumentError.value(mode, 'mode cannot be read-only');
    }
    // Test that parent dir exists as we don't get any error...
    /*
    var dir = vm_io.Directory(dirname(path));
    if (!dir.existsSync()) {
      throw 'Parent directory does not exists';
    }

     */
    var ioMode = fileWriteMode(mode);
    var ioSink = ioFile.openWrite(mode: ioMode, encoding: encoding);
    final sink = WriteFileSinkNode(ioSink);

    return sink;
  }

  FileNode _me(_) => this;

  @override
  Stream<Uint8List> openRead([int start, int end]) {
    // Node is end inclusive!
    return ReadFileStreamCtrlNode(intListStreamToUint8ListStream(
            ioFile.openRead(start, end != null ? end - 1 : null)))
        .stream;
  }

  @override
  Future<FileNode> rename(String newPath) async {
    await ioWrap(ioFile.rename(newPath));
    return FileNode(newPath);
  }

  @override
  Future<FileNode> copy(String newPath) async {
    await ioWrap(ioFile.copy(newPath));
    return FileNode(newPath);
  }

  @override
  Future<FileNode> writeAsBytes(List<int> bytes,
          {FileMode mode = FileMode.write, bool flush = false}) =>
      ioWrap(ioFile.writeAsBytes(bytes,
              mode: fileWriteMode(mode), flush: flush))
          .then(_me);

  @override
  Future<FileNode> writeAsString(String contents,
          {FileMode mode = FileMode.write,
          Encoding encoding = utf8,
          bool flush = false}) =>
      ioWrap(ioFile.writeAsString(contents,
              mode: fileWriteMode(mode), encoding: encoding, flush: flush))
          .then(_me);

  @override
  Future<Uint8List> readAsBytes() async =>
      asUint8List(await ioWrap(ioFile.readAsBytes()));

  @override
  Future<String> readAsString({Encoding encoding = utf8}) =>
      _wrapFutureString(ioFile.readAsString(encoding: encoding));

  @override
  File get absolute => FileNode.io(ioFile.absolute);

  @override
  String toString() => "File: '$path'";
}
