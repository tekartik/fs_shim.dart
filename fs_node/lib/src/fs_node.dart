import 'dart:async';
import 'dart:typed_data';

import 'package:fs_shim/fs.dart' as fs;
import 'package:fs_shim/fs.dart';

import 'package:tekartik_fs_node/src/file_system_node.dart';
import 'package:tekartik_fs_node/src/import_common.dart';

import 'file_system_exception_node.dart';
import 'import_common_node.dart' as io;

export 'dart:async';
export 'dart:convert';

FileSystemNode _fileSystemNode;

FileSystemNode get fileSystemNode => _fileSystemNode ??= FileSystemNode();

io.FileMode fileWriteMode(fs.FileMode fsFileMode) {
  fsFileMode ??= fs.FileMode.write;
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

FileSystemExceptionNode ioWrapError(e) {
  // devPrint('error $e ${e.runtimeType}');
  if (e is io.FileSystemException) {
    return FileSystemExceptionNode.io(e);
  } else {
    // print(e.toString());
    return FileSystemExceptionNode.fromString(e.toString());
  }
  // return e;
}

Future<T> ioWrap<T>(Future<T> future) async {
  try {
    return await future;
  } on io.FileSystemException catch (e) {
    //io.stderr.writeln(st);
    throw ioWrapError(e);
  } catch (e) {
    // catch anything in javascript
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

class WriteFileSinkNode implements StreamSink<List<int>> {
  io.IOSink ioSink;

  WriteFileSinkNode(this.ioSink);

  @override
  void add(List<int> data) {
    ioSink.add(data);
  }

  // always flush on node
  @override
  Future close() async {
    await ioWrap(ioSink.flush());
    await ioWrap(ioSink.close());
  }

  @override
  void addError(errorEvent, [StackTrace stackTrace]) {
    ioSink.addError(errorEvent, stackTrace);
  }

  @override
  Future get done => ioWrap(ioSink.done);

  @override
  // not supported for node...
  Future addStream(Stream<List<int>> stream) async {
    await stream.listen((List<int> data) {
      add(data);
    }).asFuture();
  }
}

class ReadFileStreamCtrlNode {
  ReadFileStreamCtrlNode(this._nodeStream) {
    _ctlr = StreamController();
    _nodeStream.listen((data) {
      _ctlr.add(data);
    }, onError: (error, StackTrace stackTrace) {
      _ctlr.addError(ioWrapError(error));
    }, onDone: () {
      _ctlr.close();
    });
  }

  final Stream<Uint8List> _nodeStream;
  StreamController<Uint8List> _ctlr;

  Stream<Uint8List> get stream => _ctlr.stream;
}
