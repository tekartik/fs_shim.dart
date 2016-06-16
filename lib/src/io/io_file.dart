library fs_shim.src.io.io_file;

import '../../fs.dart' as fs;
export '../../fs.dart' show FileSystemEntityType;
import 'dart:io' as io;
import 'dart:async';
import 'io_fs.dart';
import '../../fs_io.dart';
import 'io_file_system_entity.dart';

Future<File> _wrapFutureFile(Future<File> future) =>
    ioWrap(future) as Future<File>;
Future<String> _wrapFutureString(Future<String> future) =>
    ioWrap(future) as Future<String>;

class FileImpl extends FileSystemEntityImpl implements File {
  io.File get ioFile => ioFileSystemEntity;

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
          new FileImpl(ioFileSystemEntity.path)));

  @override
  Future<FileImpl> copy(String newPath) => _wrapFutureFile(ioFile
      .copy(newPath)
      .then((io.FileSystemEntity ioFileSystemEntity) =>
          new FileImpl(ioFileSystemEntity.path)));

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
  Future<List<int>> readAsBytes() =>
      ioWrap(ioFile.readAsBytes()) as Future<List<int>>;

  @override
  Future<String> readAsString({Encoding encoding: UTF8}) =>
      _wrapFutureString(ioFile.readAsString(encoding: encoding));

  @override
  File get absolute => new FileImpl.io(ioFile.absolute);
}
