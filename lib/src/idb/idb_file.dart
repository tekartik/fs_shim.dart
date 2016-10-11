import '../../fs.dart' as fs;
import '../common/fs_mixin.dart';
import 'idb_file_system_entity.dart';
import 'idb_fs.dart';

class IdbFile extends IdbFileSystemEntity with FileMixin implements fs.File {
  IdbFile(IdbFileSystem fs, String path) : super(fs, path);

  IdbFileSystem get _fs => super.fs;

  Future<IdbFile> create({bool recursive: false}) {
    return _fs.createFile(path, recursive: recursive).then((_) => this);
  }

  fs.FileSystemEntityType get type => fs.FileSystemEntityType.FILE;

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
        .rename(type, path, newPath)
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

  @override
  IdbFile get absolute => new IdbFile(_fs, idbMakePathAbsolute(path));

  @override
  String toString() => "File: '$path'";
}
