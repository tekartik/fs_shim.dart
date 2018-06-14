import 'package:tekartik_fs_node/src/file_system_node.dart';

import 'dart:async';

import 'package:fs_shim/fs.dart' as fs;
import 'package:fs_shim/fs.dart';
import 'file_system_exception_node.dart';
import 'import_common_node.dart' as io;

export 'dart:async';
export 'dart:convert';

FileSystemNode _fileSystemNode;
FileSystemNode get fileSystemNode => _fileSystemNode ??= new FileSystemNode();

io.FileMode fileWriteMode(fs.FileMode fsFileMode) {
  if (fsFileMode == null) fsFileMode = fs.FileMode.write;
  return unwrapIoFileModeImpl(fsFileMode);
}

// FileMode Wrap/unwrap
FileMode wrapIoFileMode(io.FileMode ioFileMode) =>
    wrapIofileModeImpl(ioFileMode);
io.FileMode unwrapIoFileMode(FileMode fileMode) =>
    unwrapIoFileModeImpl(fileMode);

// FileSystemEntityType Wrap/unwrap
FileSystemEntityType wrapIoFileSystemEntityType(
        io.FileSystemEntityType ioFileSystemEntityType) =>
    wrapIoFileSystemEntityTypeImpl(ioFileSystemEntityType);
io.FileSystemEntityType unwrapIoFileSystemEntityType(
        FileSystemEntityType fileSystemEntityType) =>
    unwrapIoFileSystemEntityTypeImpl(fileSystemEntityType);

io.FileMode unwrapIoFileModeImpl(fs.FileMode fsFileMode) {
  switch (fsFileMode) {
    case fs.FileMode.write:
      return io.FileMode.write;
    case fs.FileMode.read:
      return io.FileMode.read;
    case fs.FileMode.append:
      return io.FileMode.append;
    default:
      throw null;
  }
}

fs.FileMode wrapIofileModeImpl(io.FileMode ioFileMode) {
  switch (ioFileMode) {
    case io.FileMode.write:
      return fs.FileMode.write;
    case io.FileMode.read:
      return fs.FileMode.read;
    case io.FileMode.append:
      return fs.FileMode.append;
    default:
      throw null;
  }
}

ioWrapError(e) {
  if (e is io.FileSystemException) {
    return new FileSystemExceptionNode.io(e);
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
    fs.FileSystemEntityType type) {
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

  Future addStream(Stream<List<int>> stream) => ioSink.addStream(stream);
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
