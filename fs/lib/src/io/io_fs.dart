library fs_shim.src.io.io_fs;

import 'dart:async';
import 'dart:io' as io;

import 'package:dart2_constant/io.dart' as constant;

import '../../fs.dart' as fs;
import 'io_file_system_exception.dart';

export 'dart:async';
export 'dart:convert';

io.FileMode fileWriteMode(fs.FileMode fsFileMode) {
  if (fsFileMode == null) fsFileMode = fs.FileMode.write;
  return unwrapIofileModeImpl(fsFileMode);
}

io.FileMode unwrapIofileModeImpl(fs.FileMode fsFileMode) {
  switch (fsFileMode) {
    case fs.FileMode.write:
      return constant.FileMode.write;
    case fs.FileMode.read:
      return constant.FileMode.read;
    case fs.FileMode.append:
      return constant.FileMode.append;
    default:
      throw null;
  }
}

fs.FileMode wrapIofileModeImpl(io.FileMode ioFileMode) {
  switch (ioFileMode) {
    case constant.FileMode.write:
      return fs.FileMode.write;
    case constant.FileMode.read:
      return fs.FileMode.read;
    case constant.FileMode.append:
      return fs.FileMode.append;
    default:
      throw null;
  }
}

dynamic ioWrapError(e) {
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

fs.FileSystemEntityType wrapIoFileSystemEntityTypeImpl(
    io.FileSystemEntityType type) {
  switch (type) {
    case constant.FileSystemEntityType.file:
      return fs.FileSystemEntityType.file;
    case constant.FileSystemEntityType.directory:
      return fs.FileSystemEntityType.directory;
    case constant.FileSystemEntityType.link:
      return fs.FileSystemEntityType.link;
    case constant.FileSystemEntityType.notFound:
      return fs.FileSystemEntityType.notFound;
    default:
      throw type;
  }
}

io.FileSystemEntityType unwrapIoFileSystemEntityTypeImpl(
    fs.FileSystemEntityType type) {
  switch (type) {
    case fs.FileSystemEntityType.file:
      return constant.FileSystemEntityType.file;
    case fs.FileSystemEntityType.directory:
      return constant.FileSystemEntityType.directory;
    case fs.FileSystemEntityType.link:
      return constant.FileSystemEntityType.link;
    case fs.FileSystemEntityType.notFound:
      return constant.FileSystemEntityType.notFound;
    default:
      throw type;
  }
}

class IoWriteFileSink implements StreamSink<List<int>> {
  io.IOSink ioSink;

  IoWriteFileSink(this.ioSink);

  @override
  void add(List<int> data) {
    ioSink.add(data);
  }

  @override
  Future close() => ioWrap(ioSink.close());

  @override
  void addError(errorEvent, [StackTrace stackTrace]) {
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
    ioStream.listen((List<int> data) {
      _ctlr.add(data);
    }, onError: (error, StackTrace stackTrace) {
      _ctlr.addError(ioWrapError(error));
    }, onDone: () {
      _ctlr.close();
    });
  }

  Stream<List<int>> ioStream;
  StreamController<List<int>> _ctlr;

  Stream<List<int>> get stream => _ctlr.stream;
}
