library fs_shim.src.io.io_file;

import 'dart:async';
import 'dart:io' as io;

import '../../fs.dart' as fs;
import '../../fs_io.dart';
import 'io_file_system_entity.dart';
import 'io_fs.dart';

export '../../fs.dart' show FileSystemEntityType;

Future<File> _wrapFutureFile(Future<File> future) => ioWrap(future);

Future<String> _wrapFutureString(Future<String> future) => ioWrap(future);

class FileImpl extends FileSystemEntityImpl implements File {
  io.File get ioFile => ioFileSystemEntity as io.File;

  FileImpl.io(io.File file) {
    ioFileSystemEntity = file;
  }

  FileImpl(String path) {
    ioFileSystemEntity = new io.File(path);
  }

  @override
  Future<FileImpl> create({bool recursive: false}) //
      =>
      ioWrap(ioFile.create(recursive: recursive)).then(_me);

  // ioFile.openWrite(mode: _fileMode(mode), encoding: encoding);
  @override
  StreamSink<List<int>> openWrite(
      {fs.FileMode mode: fs.FileMode.WRITE, Encoding encoding: UTF8}) {
    IoWriteFileSink sink = new IoWriteFileSink(
        ioFile.openWrite(mode: fileWriteMode(mode), encoding: encoding));
    return sink;
  }

  FileImpl _me(_) => this;

  @override
  Stream<List<int>> openRead([int start, int end]) {
    return new IoReadFileStreamCtrl(ioFile.openRead(start, end)).stream;
  }

  @override
  Future<FileImpl> rename(String newPath) => _wrapFutureFile(ioFile
      .rename(newPath)
      .then((io.FileSystemEntity ioFileSystemEntity) =>
          new FileImpl(ioFileSystemEntity.path))) as Future<FileImpl>;

  @override
  Future<FileImpl> copy(String newPath) => _wrapFutureFile(ioFile
      .copy(newPath)
      .then((io.FileSystemEntity ioFileSystemEntity) =>
          new FileImpl(ioFileSystemEntity.path))) as Future<FileImpl>;

  @override
  Future<FileImpl> writeAsBytes(List<int> bytes,
          {fs.FileMode mode: fs.FileMode.WRITE, bool flush: false}) =>
      ioWrap(ioFile.writeAsBytes(bytes,
              mode: fileWriteMode(mode), flush: flush))
          .then(_me);

  @override
  Future<FileImpl> writeAsString(String contents,
          {fs.FileMode mode: fs.FileMode.WRITE,
          Encoding encoding: UTF8,
          bool flush: false}) =>
      ioWrap(ioFile.writeAsString(contents,
              mode: fileWriteMode(mode), encoding: encoding, flush: flush))
          .then(_me);

  @override
  Future<List<int>> readAsBytes() => ioWrap(ioFile.readAsBytes());

  @override
  Future<String> readAsString({Encoding encoding: UTF8}) =>
      _wrapFutureString(ioFile.readAsString(encoding: encoding));

  @override
  File get absolute => new FileImpl.io(ioFile.absolute);
}
