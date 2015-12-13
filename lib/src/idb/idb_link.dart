library fs_shim.src.idb_link;

import 'idb_fs.dart';
import '../../fs.dart' as fs;

class IdbLink extends IdbFileSystemEntity implements fs.Link {
  IdbLink _me(_) => this;
  IdbLink(IdbFileSystem fs, String path) : super(fs, path);

  /*
  Future<IdbFile> create({bool recursive: false}) {
    return _fs.createFile(path, recursive: recursive).then((_) => this);
  }

  fs.FileSystemEntityType get _type => fs.FileSystemEntityType.FILE;

  // don't care about encoding - assume UTF8
  @override
  StreamSink<List<int>> openWrite(
          {fs.FileMode mode: fs.FileMode.WRITE, Encoding encoding: UTF8}) //
      =>
      _fs.openWrite(path, mode: mode);

  @override
  Stream<List<int>> openRead([int start, int end]) =>
      _fs.openRead(path, start, end);

  @override
  Future<IdbFile> rename(String newPath) {
    return _fs
        .rename(_type, path, newPath)
        .then((_) => new IdbFile(_fs, newPath));
  }

  @override
  Future<IdbFile> copy(String newPath) {
    return _fs.copyFile(path, newPath).then((_) => new IdbFile(_fs, newPath));
  }

  @override
  Future<IdbFile> writeAsBytes(List<int> bytes,
          {fs.FileMode mode: fs.FileMode.WRITE, bool flush: false}) =>
      doWriteAsBytes(bytes, mode: mode, flush: flush);

  @override
  Future<IdbFile> writeAsString(String contents,
          {fs.FileMode mode: fs.FileMode.WRITE,
          Encoding encoding: UTF8,
          bool flush: false}) =>
      doWriteAsString(contents, mode: mode, encoding: encoding, flush: flush);
  */
  @override
  IdbLink get absolute => new IdbLink(super.fs, idbMakePathAbsolute(path));

  @override
  Future<IdbLink> rename(String newPath) {
    return null;
  }

  Future<IdbLink> create(String target, {bool recursive: false}) {
    return super.fs.createLink(path, target, recursive: recursive).then(_me);
  }
}
