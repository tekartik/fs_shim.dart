import '../../fs.dart' as fs;
import 'idb_file_system_entity.dart';
import 'idb_fs.dart';

class IdbLink extends IdbFileSystemEntity implements fs.Link {
  IdbLink _me(_) => this;
  IdbLink(IdbFileSystem fs, String path) : super(fs, path);

  IdbFileSystem get _fs => super.fs;

  @override
  fs.FileSystemEntityType get type => fs.FileSystemEntityType.link;

  /*
  Future<IdbFile> create({bool recursive: false}) {
    return _fs.createFile(path, recursive: recursive).then((_) => this);
  }



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
*/
  @override
  Future<String> target() => _fs.linkTarget(path);

  @override
  IdbLink get absolute => new IdbLink(super.fs, idbMakePathAbsolute(path));

  @override
  Future<IdbLink> rename(String newPath) {
    return _fs
        .rename(type, path, newPath)
        .then((_) => new IdbLink(_fs, newPath));
  }

  @override
  Future<IdbLink> create(String target, {bool recursive: false}) {
    return _fs.createLink(path, target, recursive: recursive).then(_me);
  }

  @override
  String toString() => "Link: '$path'";
}
