import 'package:dart2_constant/convert.dart' as convert;
import 'package:fs_shim/fs.dart';
import 'package:fs_shim/src/common/import.dart';

class FileSystemNone implements FileSystem {
  @override
  Directory directory(String path) => throw UnsupportedError("fs.directory");

  @override
  File file(String path) => throw UnsupportedError("fs.file");

  @override
  Future<bool> isDirectory(String path) =>
      throw UnsupportedError("fs.isDirectory");

  @override
  Future<bool> isFile(String path) => throw UnsupportedError("fs.isFile");

  @override
  Future<bool> isLink(String path) => throw UnsupportedError("fs.isLink");

  @override
  Link link(String path) => throw UnsupportedError("fs.link");

  @override
  String get name => throw UnsupportedError("fs.name");

  @override
  Directory newDirectory(String path) => directory(path);

  @override
  File newFile(String path) => file(path);

  @override
  Link newLink(String path) => link(path);

  @override
  Context get pathContext => path;

  @override
  Context get path => throw UnsupportedError("fs.path");

  @override
  bool get supportsFileLink => throw UnsupportedError("fs.supportsFileLink");

  @override
  bool get supportsLink => throw UnsupportedError("fs.supportsLink");

  @override
  Future<FileSystemEntityType> type(String path, {bool followLinks = true}) =>
      throw UnsupportedError("fs.type");
}

abstract class FileNone implements File {
  @override
  File get absolute => throw UnsupportedError("file.absolute");

  @override
  Future<File> copy(String newPath) => throw UnsupportedError("file.copy");

  @override
  Future<File> create({bool recursive = false}) =>
      throw UnsupportedError("file.create");

  @override
  Stream<List<int>> openRead([int start, int end]) =>
      throw UnsupportedError("file.openRead");

  @override
  StreamSink<List<int>> openWrite(
          {FileMode mode = FileMode.write, Encoding encoding = convert.utf8}) =>
      throw UnsupportedError("file.openWrite");

  @override
  Future<List<int>> readAsBytes() => throw UnsupportedError("file.readAsBytes");

  @override
  Future<String> readAsString({Encoding encoding = convert.utf8}) async {
    var bytes = await readAsBytes();
    return encoding.decode(bytes);
  }

  @override
  Future<File> writeAsBytes(List<int> bytes,
          {FileMode mode = FileMode.write, bool flush = false}) =>
      throw UnsupportedError("file.writeAsBytes");

  @override
  Future<File> writeAsString(String contents,
      {FileMode mode = FileMode.write,
      Encoding encoding = convert.utf8,
      bool flush = false}) async {
    return await writeAsBytes(encoding.encode(contents),
        mode: mode, flush: flush);
  }
}

abstract class FileSystemEntityNone implements FileSystemEntity {
  @override
  Future<FileSystemEntity> delete({bool recursive = false}) =>
      throw UnsupportedError("fse.delete");

  @override
  Future<bool> exists() => throw UnsupportedError("fse.exists");

  @override
  bool get isAbsolute => throw UnsupportedError("fse.isAbsolute");

  @override
  Directory get parent => throw UnsupportedError("fse.parent");

  @override
  String get path => throw UnsupportedError("fse.path");

  @override
  Future<FileSystemEntity> rename(String newPath) =>
      throw UnsupportedError("fse.rename");

  @override
  Future<FileStat> stat() => throw UnsupportedError("fse.stat");

  @override
  FileSystem get fs => throw UnsupportedError("fse.fs");
}

abstract class DirectoryNone implements Directory {
  @override
  Directory get absolute => throw UnsupportedError("directory.absolute");

  @override
  Future<Directory> create({bool recursive = false}) =>
      throw UnsupportedError("directory.create");

  @override
  Stream<FileSystemEntity> list(
          {bool recursive = false, bool followLinks = true}) =>
      throw UnsupportedError("directory.list");
}
