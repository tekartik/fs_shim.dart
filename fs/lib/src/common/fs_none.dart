import 'package:fs_shim/fs.dart';
import 'package:fs_shim/src/common/import.dart';
import 'package:dart2_constant/convert.dart' as convert;

class FileSystemNone implements FileSystem {
  @override
  Directory directory(String path) =>
      throw new UnsupportedError("fs.directory");

  @override
  File file(String path) => throw new UnsupportedError("fs.file");

  @override
  Future<bool> isDirectory(String path) =>
      throw new UnsupportedError("fs.isDirectory");

  @override
  Future<bool> isFile(String path) => throw new UnsupportedError("fs.isFile");

  @override
  Future<bool> isLink(String path) => throw new UnsupportedError("fs.isLink");

  @override
  Link link(String path) => throw new UnsupportedError("fs.link");

  @override
  String get name => throw new UnsupportedError("fs.name");

  @override
  Directory newDirectory(String path) => directory(path);

  @override
  File newFile(String path) => file(path);

  @override
  Link newLink(String path) => link(path);

  @override
  Context get pathContext => path;

  @override
  Context get path => throw new UnsupportedError("fs.path");

  @override
  bool get supportsFileLink =>
      throw new UnsupportedError("fs.supportsFileLink");

  @override
  bool get supportsLink => throw new UnsupportedError("fs.supportsLink");

  @override
  Future<FileSystemEntityType> type(String path, {bool followLinks: true}) =>
      throw new UnsupportedError("fs.type");
}

abstract class FileNone implements File {
  @override
  File get absolute => throw new UnsupportedError("file.absolute");

  @override
  Future<File> copy(String newPath) => throw new UnsupportedError("file.copy");

  @override
  Future<File> create({bool recursive: false}) =>
      throw new UnsupportedError("file.create");

  @override
  Stream<List<int>> openRead([int start, int end]) =>
      throw new UnsupportedError("file.openRead");

  @override
  StreamSink<List<int>> openWrite(
          {FileMode mode: FileMode.write, Encoding encoding: convert.utf8}) =>
      throw new UnsupportedError("file.openWrite");

  @override
  Future<List<int>> readAsBytes() =>
      throw new UnsupportedError("file.readAsBytes");

  @override
  Future<String> readAsString({Encoding encoding: convert.utf8}) async {
    var bytes = await readAsBytes();
    return encoding.decode(bytes);
  }

  @override
  Future<File> writeAsBytes(List<int> bytes,
          {FileMode mode: FileMode.write, bool flush: false}) =>
      throw new UnsupportedError("file.writeAsBytes");

  @override
  Future<File> writeAsString(String contents,
      {FileMode mode: FileMode.write,
      Encoding encoding: convert.utf8,
      bool flush: false}) async {
    return await writeAsBytes(encoding.encode(contents),
        mode: mode, flush: flush);
  }
}

abstract class FileSystemEntityNone implements FileSystemEntity {
  @override
  Future<FileSystemEntity> delete({bool recursive: false}) =>
      throw new UnsupportedError("fse.delete");

  @override
  Future<bool> exists() => throw new UnsupportedError("fse.exists");

  @override
  bool get isAbsolute => throw new UnsupportedError("fse.isAbsolute");

  @override
  Directory get parent => throw new UnsupportedError("fse.parent");

  @override
  String get path => throw new UnsupportedError("fse.path");

  @override
  Future<FileSystemEntity> rename(String newPath) =>
      throw new UnsupportedError("fse.rename");

  @override
  Future<FileStat> stat() => throw new UnsupportedError("fse.stat");

  @override
  FileSystem get fs => throw new UnsupportedError("fse.fs");
}

abstract class DirectoryNone implements Directory {
  @override
  Directory get absolute => throw new UnsupportedError("directory.absolute");

  @override
  Future<Directory> create({bool recursive: false}) =>
      throw new UnsupportedError("directory.create");

  @override
  Stream<FileSystemEntity> list(
          {bool recursive: false, bool followLinks: true}) =>
      throw new UnsupportedError("directory.list");
}
