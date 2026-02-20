// ignore_for_file: public_member_api_docs

library;

import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;
import 'dart:typed_data';

import 'package:fs_shim/fs.dart' as fs;
import 'package:fs_shim/fs_io.dart';
import 'package:fs_shim/src/common/compat.dart';
import 'package:fs_shim/src/common/fs_mixin.dart'
    show FileExecutableSupport, FileMixin;
import 'package:fs_shim/src/common/import.dart' show isDebug, FileStreamSink;
import 'package:fs_shim/src/io/io_random_access_file.dart';

import 'io_file_system_entity.dart';
import 'io_fs.dart';

Future<T> _wrapFutureFile<T>(Future<T> future) => ioWrap(future);

Future<String> _wrapFutureString(Future<String> future) => ioWrap(future);

class FileIoImpl extends FileSystemEntityIoImpl
    with FileMixin
    implements File, FileExecutableSupport {
  io.File? get ioFile => ioFileSystemEntity as io.File?;

  FileIoImpl.io(io.File file) {
    ioFileSystemEntity = file;
  }

  FileIoImpl(String path) {
    ioFileSystemEntity = io.File(path);
  }

  @override
  Future<FileIoImpl> create({bool recursive = false}) //
  => ioWrap(ioFile!.create(recursive: recursive)).then(_me);

  @override
  FileStreamSink openWrite({
    fs.FileMode mode = fs.FileMode.write,
    Encoding encoding = utf8,
  }) {
    final sink = IoWriteFileSink(
      ioFile!.openWrite(mode: unwrapFileMode(mode), encoding: encoding),
    );
    return sink;
  }

  @override
  Future<fs.RandomAccessFile> open({fs.FileMode mode = FileMode.read}) {
    return ioWrapCall(() async {
      var ioRandomAccessFile = await ioFile!.open(mode: unwrapFileMode(mode));
      return IoRandomAccessFile(ioRandomAccessFile);
    });
  }

  FileIoImpl _me(_) => this;

  @override
  Stream<Uint8List> openRead([int? start, int? end]) {
    return IoReadFileStreamCtrl(
      intListStreamToUint8ListStream(ioFile!.openRead(start, end)),
    ).stream;
  }

  @override
  Future<FileIoImpl> rename(String newPath) => _wrapFutureFile(
    ioFile!
        .rename(newPath)
        .then(
          (io.FileSystemEntity ioFileSystemEntity) =>
              FileIoImpl(ioFileSystemEntity.path),
        ),
  );

  @override
  Future<FileIoImpl> copy(String newPath) => _wrapFutureFile(
    ioFile!
        .copy(newPath)
        .then(
          (io.FileSystemEntity ioFileSystemEntity) =>
              FileIoImpl(ioFileSystemEntity.path),
        ),
  );

  @override
  Future<FileIoImpl> writeAsBytes(
    List<int> bytes, {
    fs.FileMode mode = fs.FileMode.write,
    bool flush = false,
  }) => ioWrap(
    ioFile!.writeAsBytes(bytes, mode: unwrapIoFileMode(mode), flush: flush),
  ).then(_me);

  @override
  Future<FileIoImpl> writeAsString(
    String contents, {
    fs.FileMode mode = fs.FileMode.write,
    Encoding encoding = utf8,
    bool flush = false,
  }) => ioWrap(
    ioFile!.writeAsString(
      contents,
      mode: unwrapFileMode(mode),
      encoding: encoding,
      flush: flush,
    ),
  ).then(_me);

  @override
  Future<Uint8List> readAsBytes() async =>
      asUint8List(await ioWrap(ioFile!.readAsBytes()));

  @override
  Future<String> readAsString({Encoding encoding = utf8}) =>
      _wrapFutureString(ioFile!.readAsString(encoding: encoding));

  @override
  File get absolute => FileIoImpl.io(ioFile!.absolute);

  @override
  Future<void> setExecutablePermission(bool enable) async {
    if (!Platform.isWindows) {
      try {
        await Process.run('chmod', [if (enable) '+x' else '-x', absolute.path]);
      } catch (e) {
        if (isDebug) {
          // ignore: avoid_print
          print('setExecutablePermission error $e');
        }
      }
    }
  }
}
