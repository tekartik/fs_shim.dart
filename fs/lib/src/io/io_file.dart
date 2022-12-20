// ignore_for_file: public_member_api_docs

library fs_shim.src.io.io_file;

import 'dart:io' as io;
import 'dart:typed_data';

import 'package:fs_shim/fs.dart' as fs;
import 'package:fs_shim/fs_io.dart';
import 'package:fs_shim/src/common/compat.dart';
import 'package:fs_shim/src/common/fs_mixin.dart'
    show FileExecutableSupport, FileMixin;
import 'package:fs_shim/src/common/import.dart' show isDebug;
import 'package:fs_shim/src/io/io_random_access_file.dart';

import 'io_file_system_entity.dart';
import 'io_fs.dart';

export 'package:fs_shim/fs.dart' show FileSystemEntityType;

Future<T> _wrapFutureFile<T>(Future<T> future) => ioWrap(future);

Future<String> _wrapFutureString(Future<String> future) => ioWrap(future);

class FileImpl extends FileSystemEntityImpl
    with FileMixin
    implements File, FileExecutableSupport {
  io.File? get ioFile => ioFileSystemEntity as io.File?;

  FileImpl.io(io.File file) {
    ioFileSystemEntity = file;
  }

  FileImpl(String path) {
    ioFileSystemEntity = io.File(path);
  }

  @override
  Future<FileImpl> create({bool recursive = false}) //
      =>
      ioWrap(ioFile!.create(recursive: recursive)).then(_me);

  // ioFile.openWrite(mode: _fileMode(mode), encoding: encoding);
  @override
  StreamSink<List<int>> openWrite(
      {fs.FileMode mode = fs.FileMode.write, Encoding encoding = utf8}) {
    final sink = IoWriteFileSink(
        ioFile!.openWrite(mode: unwrapFileMode(mode), encoding: encoding));
    return sink;
  }

  @override
  Future<fs.RandomAccessFile> open({fs.FileMode mode = FileMode.read}) {
    return ioWrapCall(() async {
      var ioRandomAccessFile = await ioFile!.open(mode: unwrapFileMode(mode));
      return IoRandomAccessFile(ioRandomAccessFile);
    });
  }

  FileImpl _me(_) => this;

  @override
  Stream<Uint8List> openRead([int? start, int? end]) {
    return IoReadFileStreamCtrl(
            intListStreamToUint8ListStream(ioFile!.openRead(start, end)))
        .stream;
  }

  @override
  Future<FileImpl> rename(String newPath) => _wrapFutureFile(ioFile!
      .rename(newPath)
      .then((io.FileSystemEntity ioFileSystemEntity) =>
          FileImpl(ioFileSystemEntity.path)));

  @override
  Future<FileImpl> copy(String newPath) => _wrapFutureFile(ioFile!
      .copy(newPath)
      .then((io.FileSystemEntity ioFileSystemEntity) =>
          FileImpl(ioFileSystemEntity.path)));

  @override
  Future<FileImpl> writeAsBytes(List<int> bytes,
          {fs.FileMode mode = fs.FileMode.write, bool flush = false}) =>
      ioWrap(ioFile!
              .writeAsBytes(bytes, mode: unwrapIoFileMode(mode), flush: flush))
          .then(_me);

  @override
  Future<FileImpl> writeAsString(String contents,
          {fs.FileMode mode = fs.FileMode.write,
          Encoding encoding = utf8,
          bool flush = false}) =>
      ioWrap(ioFile!.writeAsString(contents,
              mode: unwrapFileMode(mode), encoding: encoding, flush: flush))
          .then(_me);

  @override
  Future<Uint8List> readAsBytes() async =>
      asUint8List(await ioWrap(ioFile!.readAsBytes()));

  @override
  Future<String> readAsString({Encoding encoding = utf8}) =>
      _wrapFutureString(ioFile!.readAsString(encoding: encoding));

  @override
  File get absolute => FileImpl.io(ioFile!.absolute);

  @override
  Future<void> setExecutablePermission(bool enable) async {
    if (!Platform.isWindows) {
      try {
        await Process.run('chmod', [enable ? '+x' : '-x', absolute.path]);
      } catch (e) {
        if (isDebug) {
          print('setExecutablePermission error $e');
        }
      }
    }
  }
}
