library fs_shim.lfs_io;

import 'fs.dart' as fs;
export 'fs.dart' show FileSystemEntityType;
import 'dart:io' as io;
import 'dart:async';
import 'package:fs_shim/src/common/fs_mixin.dart';
import 'dart:convert';

final IoFileSystem ioFileSystem = new IoFileSystem();

class _IoOSError implements fs.OSError {
  io.OSError ioOSError;
  _IoOSError(this.ioOSError);
  int get errorCode => ioOSError.errorCode;
  String get message => ioOSError.message;

  @override
  String toString() => ioOSError.toString();
}

int _statusFromException(io.FileSystemException ioFse) {
  // linux error code is 2
  int status;
  if (ioFse != null && ioFse.osError != null) {
    int errorCode = ioFse.osError.errorCode;

    if (io.Platform.isWindows) {
      switch (errorCode) {
        case 2: // ERROR_FILE_NOT_FOUND
        case 3: // ERROR_PATH_NOT_FOUND
          status = fs.FileSystemException.statusNotFound;
          break;
        case 5: // ERROR_ACCESS_DENIED
          status = fs.FileSystemException.statusAccessError;
          break;
        case 145: // ERROR_DIR_NOT_EMPTY
          status =
              fs.FileSystemException.statusNotEmpty; // for recursive delete
          break;
        case 183: // ERROR_ALREADY_EXISTS
          status = fs.FileSystemException.statusAlreadyExists;
          break;
      }
    }
    if (io.Platform.isMacOS) {
      // http://www.ioplex.com/~miallen/errcmp.html
      switch (errorCode) {
        case 2: // No such file or directory
          status = fs.FileSystemException.statusNotFound;
          break;
        case 17:
          status = fs.FileSystemException.statusAlreadyExists;
          break;
        case 20: // Not a directory
          status = fs.FileSystemException.statusNotADirectory;
          break;
        case 21:
          status = fs.FileSystemException.statusIsADirectory;
          break;
        case 66: // Directory not empty
          status =
              fs.FileSystemException.statusNotEmpty; // for recursive delete
          break;
      }
    } else {
      // tested mainly on linux
      switch (errorCode) {
        case 2:
          status = fs.FileSystemException.statusNotFound;
          break;
        case 17:
          status = fs.FileSystemException.statusAlreadyExists;
          break;
        case 20:
          status = fs.FileSystemException.statusNotADirectory;
          break;
        case 21:
          status = fs.FileSystemException.statusIsADirectory;
          break;
        case 39:
          status =
              fs.FileSystemException.statusNotEmpty; // for recursive delete
          break;
      }
    }
  }
  return status;
}

class FileSystemException implements fs.FileSystemException {
  io.FileSystemException ioFse;

  FileSystemException(io.FileSystemException ioFse)
      : ioFse = ioFse,
        osError = new _IoOSError(ioFse.osError),
        status = _statusFromException(ioFse);

  @override
  final int status;

  @override
  final _IoOSError osError;

  @override
  String get message => ioFse.message;

  @override
  String get path => ioFse.path;

  @override
  String toString() =>
      "${status == null ? '' : '[${status}] '}${ioFse.toString()}";
}

abstract class FileSystemEntity implements fs.FileSystemEntity {
  io.FileSystemEntity ioFileSystemEntity;

  FileSystemEntity _me(_) => this;

  @override
  String get path => ioFileSystemEntity.path;

  @override
  String toString() => ioFileSystemEntity.toString();

  @override
  Future<bool> exists() => _wrap(ioFileSystemEntity.exists()) as Future<bool>;

  @override
  Future<fs.FileSystemEntity> delete({bool recursive: false}) //
      =>
      _wrap(ioFileSystemEntity.delete(recursive: recursive)).then(_me);

  @override
  bool get isAbsolute => ioFileSystemEntity.isAbsolute;

  @override
  Future<fs.FileStat> stat() => _wrap(ioFileSystemEntity.stat())
      .then((io.FileStat stat) => new FileStat._(stat));
  // io helper
  static Future<bool> isDirectory(String path) =>
      ioFileSystem.isDirectory(path);

  // io helper
  static Future<bool> isFile(String path) => ioFileSystem.isFile(path);
}

class FileStat implements fs.FileStat {
  FileStat._(this.ioFileStat);
  io.FileStat ioFileStat;

  @override
  DateTime get modified => ioFileStat.modified;

  @override
  int get size => ioFileStat.size;

  @override
  fs.FileSystemEntityType get type => _fsFileType(ioFileStat.type);

  @override
  String toString() => ioFileStat.toString();
}

Future<File> _wrapFutureFile(Future<File> future) =>
    _wrap(future) as Future<File>;
Future<String> _wrapFutureString(Future<String> future) =>
    _wrap(future) as Future<String>;

class File extends FileSystemEntity implements fs.File {
  io.File get ioFile => ioFileSystemEntity;

  File._(io.File file) {
    ioFileSystemEntity = file;
  }

  File(String path) {
    ioFileSystemEntity = new io.File(path);
  }

  @override
  Future<File> create({bool recursive: false}) //
      =>
      _wrap(ioFile.create(recursive: recursive)).then(_me);

  // ioFile.openWrite(mode: _fileMode(mode), encoding: encoding);
  @override
  StreamSink<List<int>> openWrite(
      {fs.FileMode mode: fs.FileMode.WRITE, Encoding encoding: UTF8}) {
    _IoWriteFileSink sink = new _IoWriteFileSink(
        ioFile.openWrite(mode: _fileWriteMode(mode), encoding: encoding));
    return sink;
  }

  File _me(_) => this;

  @override
  Stream<List<int>> openRead([int start, int end]) {
    return new _IoReadFileStreamCtrl(ioFile.openRead(start, end)).stream;
  }

  @override
  Future<File> rename(String newPath) => _wrapFutureFile(ioFile
      .rename(newPath)
      .then((io.FileSystemEntity ioFileSystemEntity) =>
          new File(ioFileSystemEntity.path)));

  @override
  Future<File> copy(String newPath) => _wrapFutureFile(ioFile
      .copy(newPath)
      .then((io.FileSystemEntity ioFileSystemEntity) =>
          new File(ioFileSystemEntity.path)));

  @override
  Future<File> writeAsBytes(List<int> bytes,
          {fs.FileMode mode: fs.FileMode.WRITE, bool flush: false}) =>
      _wrap(ioFile.writeAsBytes(bytes,
          mode: _fileWriteMode(mode), flush: flush)).then(_me);

  @override
  Future<File> writeAsString(String contents,
          {fs.FileMode mode: fs.FileMode.WRITE,
          Encoding encoding: UTF8,
          bool flush: false}) =>
      _wrap(ioFile.writeAsString(contents,
          mode: _fileWriteMode(mode),
          encoding: encoding,
          flush: flush)).then(_me);

  @override
  Future<List<int>> readAsBytes() =>
      _wrap(ioFile.readAsBytes()) as Future<List<int>>;

  @override
  Future<String> readAsString({Encoding encoding: UTF8}) =>
      _wrapFutureString(ioFile.readAsString(encoding: encoding));

  @override
  File get absolute => new File._(ioFile.absolute);
}

class Directory extends FileSystemEntity implements fs.Directory {
  io.Directory get ioDir => ioFileSystemEntity;

  Directory._(io.Directory dir) {
    ioFileSystemEntity = dir;
  }
  Directory(String path) {
    ioFileSystemEntity = new io.Directory(path);
  }

  Directory _me(_) => this;
  Directory _ioThen(io.Directory resultIoDir) {
    if (resultIoDir == null) {
      return null;
    }
    if (resultIoDir.path == ioDir.path) {
      return this;
    }
    return new Directory._(resultIoDir);
  }

  @override
  Future<Directory> create({bool recursive: false}) //
      =>
      _wrap(ioDir.create(recursive: recursive)).then(_ioThen);

  @override
  Future<Directory> rename(String newPath) => _wrap(ioDir.rename(newPath)).then(
      (io.FileSystemEntity ioFileSystemEntity) =>
          new Directory(ioFileSystemEntity.path));

  @override
  Stream<FileSystemEntity> list(
      {bool recursive: false, bool followLinks: true}) {
    var ioStream = ioDir.list(recursive: recursive, followLinks: followLinks);

    StreamSubscription<FileSystemEntity> _transformer(
        Stream<io.FileSystemEntity> input, bool cancelOnError) {
      StreamController<FileSystemEntity> controller;
      //StreamSubscription<io.FileSystemEntity> subscription;
      controller = new StreamController<FileSystemEntity>(onListen: () {
        input.listen((io.FileSystemEntity data) {
          // Duplicate the data.
          if (data is io.File) {
            controller.add(new File._(data));
          } else if (data is io.Directory) {
            controller.add(new Directory._(data));
          } else {
            controller.addError(new UnsupportedError(
                'type ${data} ${data.runtimeType} not supported'));
          }
        },
            onError: controller.addError,
            onDone: controller.close,
            cancelOnError: cancelOnError);
      }, sync: true);
      return controller.stream.listen(null);
    }

    // as Stream<io.FileSystemEntity, FileSystemEntity>;
    return ioStream.transform(
        new StreamTransformer<io.FileSystemEntity, FileSystemEntity>(
            _transformer)) as Stream<FileSystemEntity>;
  }

  @override
  Directory get absolute => new Directory._(ioDir.absolute);
}

/*
class Link extends FileSystemEntity {
  io.Link get ioLink =>  ioFileSystemEntity;

  Link._(io.Link dir) {
    ioFileSystemEntity = dir;
  }
  Link(String path) {
    ioFileSystemEntity = new io.Link(path);
  }


  //@override
  Future<Link> create(String target, {bool recursive: false}) //
  =>
      _wrap(ioLink
          .create(target, recursive: recursive)
          .then((io.Link ioLink) => this));

}
*/

class IoFileSystem extends Object
    with FileSystemMixin
    implements fs.FileSystem {
  @override
  Future<fs.FileSystemEntityType> type(String path, {bool followLinks: true}) //
      =>
      _wrap(io.FileSystemEntity.type(path, followLinks: true))
          .then((io.FileSystemEntityType ioType) => _fsFileType(ioType));

  @override
  File newFile(String path) {
    return new File(path);
  }

  @override
  Directory newDirectory(String path) {
    return new Directory(path);
  }

  String get name => 'io';
}

_wrapError(e) {
  if (e is io.FileSystemException) {
    return new FileSystemException(e);
  }
  return e;
}

Future _wrap(Future future) {
  return future.catchError((e) {
    throw _wrapError(e);
  }, test: (e) => (e is io.FileSystemException));
}

fs.FileSystemEntityType _fsFileType(io.FileSystemEntityType type) {
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

io.FileMode _fileWriteMode(fs.FileMode fsFileMode) {
  if (fsFileMode == null) fsFileMode = fs.FileMode.WRITE;
  return _fileMode(fsFileMode);
}

io.FileMode _fileMode(fs.FileMode fsFileMode) {
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

class _IoReadFileStreamCtrl {
  _IoReadFileStreamCtrl(this.ioStream) {
    _ctlr = new StreamController();
    ioStream.listen((List<int> data) {
      _ctlr.add(data);
    }, onError: (error, StackTrace stackTrace) {
      _ctlr.addError(_wrapError(error));
    }, onDone: () {
      _ctlr.close();
    });
  }
  Stream<List<int>> ioStream;
  StreamController<List<int>> _ctlr;
  Stream<List<int>> get stream => _ctlr.stream;
}

class _IoWriteFileSink implements StreamSink<List<int>> {
  io.IOSink ioSink;

  _IoWriteFileSink(this.ioSink);
  @override
  void add(List<int> data) {
    ioSink.add(data);
  }

  @override
  Future close() => _wrap(ioSink.close());

  void addError(errorEvent, [StackTrace stackTrace]) {
    ioSink.addError(errorEvent, stackTrace);
  }

  Future get done => _wrap(ioSink.done);

  Future addStream(Stream<List> stream) => ioSink.addStream(stream);
}
