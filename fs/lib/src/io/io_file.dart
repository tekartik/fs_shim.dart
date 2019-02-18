library fs_shim.src.io.io_file;

import 'dart:async';
import 'dart:io' as io;

import 'package:fs_shim/fs.dart' as fs;
import 'package:fs_shim/fs_io.dart';

import 'io_file_system_entity.dart';
import 'io_fs.dart';

export 'package:fs_shim/fs.dart' show FileSystemEntityType;

Future<T> _wrapFutureFile<T>(Future<T> future) => ioWrap(future);

Future<String> _wrapFutureString(Future<String> future) => ioWrap(future);

class FileImpl extends FileSystemEntityImpl implements File {
  io.File get ioFile => ioFileSystemEntity as io.File;

  FileImpl.io(io.File file) {
    ioFileSystemEntity = file;
  }

  FileImpl(String path) {
    ioFileSystemEntity = io.File(path);
  }

  @override
  Future<FileImpl> create({bool recursive = false}) //
      =>
      ioWrap(ioFile.create(recursive: recursive)).then(_me);

  // ioFile.openWrite(mode: _fileMode(mode), encoding: encoding);
  @override
  StreamSink<List<int>> openWrite(
      {fs.FileMode mode = fs.FileMode.write, Encoding encoding = utf8}) {
    IoWriteFileSink sink = IoWriteFileSink(
        ioFile.openWrite(mode: fileWriteMode(mode), encoding: encoding));
    return sink;
  }

  FileImpl _me(_) => this;

  @override
  Stream<List<int>> openRead([int start, int end]) {
    return IoReadFileStreamCtrl(ioFile.openRead(start, end)).stream;
  }

  @override
  Future<FileImpl> rename(String newPath) => _wrapFutureFile(ioFile
      .rename(newPath)
      .then((io.FileSystemEntity ioFileSystemEntity) =>
          FileImpl(ioFileSystemEntity.path)));

  @override
  Future<FileImpl> copy(String newPath) => _wrapFutureFile(ioFile
      .copy(newPath)
      .then((io.FileSystemEntity ioFileSystemEntity) =>
          FileImpl(ioFileSystemEntity.path)));

  @override
  Future<FileImpl> writeAsBytes(List<int> bytes,
          {fs.FileMode mode = fs.FileMode.write, bool flush = false}) =>
      ioWrap(ioFile.writeAsBytes(bytes,
              mode: fileWriteMode(mode), flush: flush))
          .then(_me);

  @override
  Future<FileImpl> writeAsString(String contents,
          {fs.FileMode mode = fs.FileMode.write,
          Encoding encoding = utf8,
          bool flush = false}) =>
      ioWrap(ioFile.writeAsString(contents,
              mode: fileWriteMode(mode), encoding: encoding, flush: flush))
          .then(_me);

  @override
  Future<List<int>> readAsBytes() => ioWrap(ioFile.readAsBytes());

  @override
  Future<String> readAsString({Encoding encoding = utf8}) =>
      _wrapFutureString(ioFile.readAsString(encoding: encoding));

  @override
  File get absolute => FileImpl.io(ioFile.absolute);
}
