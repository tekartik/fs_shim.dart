// ignore_for_file: public_member_api_docs

library;

import 'dart:async';
import 'dart:io' as io;
import 'dart:typed_data';

import 'package:fs_shim/fs.dart' as fs;

import 'io_file_system_exception.dart';

io.FileMode unwrapFileMode(fs.FileMode fsFileMode) {
  return unwrapIoFileModeImpl(fsFileMode);
}

io.FileMode unwrapIoFileModeImpl(fs.FileMode fsFileMode) {
  switch (fsFileMode) {
    case fs.FileMode.write:
      return io.FileMode.write;
    case fs.FileMode.read:
      return io.FileMode.read;
    case fs.FileMode.append:
      return io.FileMode.append;
    default:
      throw 'invalid FileMode($fsFileMode)';
  }
}

fs.FileMode wrapIoFileModeImpl(io.FileMode ioFileMode) {
  switch (ioFileMode) {
    case io.FileMode.write:
      return fs.FileMode.write;
    case io.FileMode.read:
      return fs.FileMode.read;
    case io.FileMode.append:
      return fs.FileMode.append;
    default:
      throw 'invalid io FileMode($ioFileMode)';
  }
}

Object ioWrapError(Object e) {
  if (e is io.FileSystemException) {
    return FileSystemExceptionImpl.io(e);
  }
  return e;
}

Future<T> ioWrap<T>(Future<T> future) async {
  try {
    return await future;
  } on io.FileSystemException catch (e) {
    //io.stderr.writeln(st);
    throw ioWrapError(e);
  }
}

Future<T> ioWrapCall<T>(Future<T> Function() action) async {
  try {
    return await action();
  } on io.FileSystemException catch (e) {
    //io.stderr.writeln(st);
    throw ioWrapError(e);
  }
}

T ioWrapCallSync<T>(T Function() action) {
  try {
    return action();
  } on io.FileSystemException catch (e) {
    //io.stderr.writeln(st);
    throw ioWrapError(e);
  }
}

fs.FileSystemEntityType wrapIoFileSystemEntityTypeImpl(
  io.FileSystemEntityType type,
) {
  switch (type) {
    case io.FileSystemEntityType.file:
      return fs.FileSystemEntityType.file;
    case io.FileSystemEntityType.directory:
      return fs.FileSystemEntityType.directory;
    case io.FileSystemEntityType.link:
      return fs.FileSystemEntityType.link;
    case io.FileSystemEntityType.notFound:
      return fs.FileSystemEntityType.notFound;
    default:
      throw type;
  }
}

io.FileSystemEntityType unwrapIoFileSystemEntityTypeImpl(
  fs.FileSystemEntityType type,
) {
  switch (type) {
    case fs.FileSystemEntityType.file:
      return io.FileSystemEntityType.file;
    case fs.FileSystemEntityType.directory:
      return io.FileSystemEntityType.directory;
    case fs.FileSystemEntityType.link:
      return io.FileSystemEntityType.link;
    case fs.FileSystemEntityType.notFound:
      return io.FileSystemEntityType.notFound;
    default:
      throw type;
  }
}

class IoWriteFileSink implements StreamSink<Uint8List> {
  io.IOSink ioSink;

  IoWriteFileSink(this.ioSink);

  @override
  void add(List<int> data) {
    ioSink.add(data);
  }

  @override
  Future close() => ioWrap(ioSink.close());

  @override
  void addError(errorEvent, [StackTrace? stackTrace]) {
    ioSink.addError(errorEvent, stackTrace);
  }

  @override
  Future get done => ioWrap(ioSink.done);

  @override
  Future addStream(Stream<List<int>> stream) => ioSink.addStream(stream);
}

class IoReadFileStreamCtrl {
  IoReadFileStreamCtrl(this.ioStream) {
    _ctlr = StreamController();
    ioStream.listen(
      (Uint8List data) {
        _ctlr.add(data);
      },
      onError: (Object error, StackTrace stackTrace) {
        _ctlr.addError(ioWrapError(error));
      },
      onDone: () {
        _ctlr.close();
      },
    );
  }

  Stream<Uint8List> ioStream;
  late StreamController<Uint8List> _ctlr;

  Stream<Uint8List> get stream => _ctlr.stream;
}
