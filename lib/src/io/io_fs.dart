library fs_shim.src.io.io_fs;

import 'dart:async';
import 'dart:io' as io;
import 'io_file_system_exception.dart';
import '../../fs.dart' as fs;
export 'dart:async';
export 'dart:convert';

io.FileMode fileWriteMode(fs.FileMode fsFileMode) {
  if (fsFileMode == null) fsFileMode = fs.FileMode.WRITE;
  return unwrapIofileModeImpl(fsFileMode);
}

io.FileMode unwrapIofileModeImpl(fs.FileMode fsFileMode) {
  switch (fsFileMode) {
    case fs.FileMode.WRITE:
      return io.FileMode.WRITE;
    case fs.FileMode.READ:
      return io.FileMode.READ;
    case fs.FileMode.APPEND:
      return io.FileMode.APPEND;
    default:
      throw null;
  }
}

fs.FileMode wrapIofileModeImpl(io.FileMode ioFileMode) {
  switch (ioFileMode) {
    case io.FileMode.WRITE:
      return fs.FileMode.WRITE;
    case io.FileMode.READ:
      return fs.FileMode.READ;
    case io.FileMode.APPEND:
      return fs.FileMode.APPEND;
    default:
      throw null;
  }
}

ioWrapError(e) {
  if (e is io.FileSystemException) {
    return new FileSystemExceptionImpl.io(e);
  }
  return e;
}

Future ioWrap(Future future) {
  return future.catchError((e) {
    throw ioWrapError(e);
  }, test: (e) => (e is io.FileSystemException));
}

fs.FileSystemEntityType wrapIoFileSystemEntityTypeImpl(
    io.FileSystemEntityType type) {
  switch (type) {
    case io.FileSystemEntityType.FILE:
      return fs.FileSystemEntityType.FILE;
    case io.FileSystemEntityType.DIRECTORY:
      return fs.FileSystemEntityType.DIRECTORY;
    case io.FileSystemEntityType.LINK:
      return fs.FileSystemEntityType.LINK;
    case io.FileSystemEntityType.NOT_FOUND:
      return fs.FileSystemEntityType.NOT_FOUND;
    default:
      throw type;
  }
}

io.FileSystemEntityType unwrapIoFileSystemEntityTypeImpl(
    fs.FileSystemEntityType type) {
  switch (type) {
    case fs.FileSystemEntityType.FILE:
      return io.FileSystemEntityType.FILE;
    case fs.FileSystemEntityType.DIRECTORY:
      return io.FileSystemEntityType.DIRECTORY;
    case fs.FileSystemEntityType.LINK:
      return io.FileSystemEntityType.LINK;
    case fs.FileSystemEntityType.NOT_FOUND:
      return io.FileSystemEntityType.NOT_FOUND;
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

  void addError(errorEvent, [StackTrace stackTrace]) {
    ioSink.addError(errorEvent, stackTrace);
  }

  Future get done => ioWrap(ioSink.done);

  Future addStream(Stream<List> stream) => ioSink.addStream(stream);
}

class IoReadFileStreamCtrl {
  IoReadFileStreamCtrl(this.ioStream) {
    _ctlr = new StreamController();
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
