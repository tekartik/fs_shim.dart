library fs_shim.src.lfs_mixin;

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:fs_shim/fs.dart';
import 'package:fs_shim/src/common/bytes_utils.dart';
import 'package:path/path.dart' as p;

/// FileSystem mixin
mixin FileSystemMixin implements FileSystem {
  Future<bool> _isType(String? path, FileSystemEntityType fseType,
      {bool followLinks = true}) async {
    return (await type(path, followLinks: followLinks)) == fseType;
  }

  // helper
  @override
  Future<bool> isFile(String? path) => _isType(path, FileSystemEntityType.file);

  // helper
  @override
  Future<bool> isDirectory(String? path) =>
      _isType(path, FileSystemEntityType.directory);

  // helper
  // do not follow links for link check
  @override
  Future<bool> isLink(String? path) =>
      _isType(path, FileSystemEntityType.link, followLinks: false);

  @override
  Future<FileSystemEntityType> type(String? path, {bool followLinks = true}) =>
      throw UnsupportedError('fs.type');

  @override
  bool get supportsFileLink => throw UnsupportedError('fs.supportsFileLink');

  @override
  bool get supportsLink => throw UnsupportedError('fs.supportsLink');

  /// Default implementation
  @override
  bool get supportsRandomAccess => false;

  @override
  Directory directory(String path) => throw UnsupportedError('fs.directory');

  @override
  File file(String path) => throw UnsupportedError('fs.file');

  @override
  Link link(String path) => throw UnsupportedError('fs.link');

  @override
  String get name => throw UnsupportedError('fs.name');

  @override
  p.Context get pathContext => path;

  @override
  p.Context get path => throw UnsupportedError('fs.path');
}

/// File mixin
mixin FileMixin implements File {
  @override
  File get absolute => throw UnsupportedError('file.absolute');

  @override
  Future<File> copy(String newPath) => throw UnsupportedError('file.copy');

  @override
  Future<File> create({bool recursive = false}) =>
      throw UnsupportedError('file.create');

  @override
  Stream<Uint8List> openRead([int? start, int? end]) =>
      throw UnsupportedError('file.openRead');

  @override
  StreamSink<List<int>> openWrite(
          {FileMode mode = FileMode.write, Encoding encoding = utf8}) =>
      throw UnsupportedError('file.openWrite');

  @override
  Future<File> writeAsBytes(Uint8List bytes,
          {FileMode mode = FileMode.write, bool flush = false}) async =>
      await doWriteAsBytes(bytes, mode: mode, flush: flush);

  @override
  Future<File> writeAsString(String contents,
      {FileMode mode = FileMode.write,
      Encoding encoding = utf8,
      bool flush = false}) async {
    return await writeAsBytes(asUint8List(encoding.encode(contents)),
        mode: mode, flush: flush);
  }

  @override
  String get path;

  /// Write bytes
  Future<FileMixin> doWriteAsBytes(List<int> bytes,
      {FileMode mode = FileMode.write, bool flush = false}) async {
    var sink = openWrite(mode: mode)..add(bytes);
    await sink.close();
    return this;
  }

  /// Write String
  Future<FileMixin> doWriteAsString(String contents,
          {FileMode mode = FileMode.write,
          Encoding encoding = utf8,
          bool flush = false}) =>
      doWriteAsBytes(encoding.encode(contents), mode: mode, flush: flush);

  @override
  Future<Uint8List> readAsBytes() => doReadAsBytes();

  String _tryDecode(Uint8List bytes, Encoding encoding) {
    try {
      return encoding.decode(bytes);
    } catch (e) {
      throw FormatException(
          "Failed to decode data using encoding '${encoding.name}' $e", path);
    }
  }

  /// Read bytes
  Future<Uint8List> doReadAsBytes() async {
    return streamToBytes(openRead());
  }

  @override
  Future<String> readAsString({Encoding encoding = utf8}) async {
    var content = await readAsBytes();
    return _tryDecode(content, encoding);
  }

  @override
  Future<RandomAccessFile> open({FileMode mode = FileMode.read}) {
    throw UnsupportedError('File.open not supported in this file system');
  }
}

/// File stat mode mixin.
mixin FileStatModeMixin implements FileStat {
  @override
  int get mode => FileStat.modeNotSupported;
}

/// Special set meta support
abstract class FileExecutableSupport implements File {
  /// Set executable permission on a file.
  Future<void> setExecutablePermission(bool enable);
}

/// File system entity mixin.
mixin FileSystemEntityMixin implements FileSystemEntity {
  @override
  Future<FileSystemEntity> delete({bool recursive = false}) =>
      throw UnsupportedError('fse.delete');

  @override
  Future<bool> exists() => throw UnsupportedError('fse.exists');

  @override
  bool get isAbsolute => throw UnsupportedError('fse.isAbsolute');

  @override
  Directory get parent => throw UnsupportedError('fse.parent');

  @override
  String get path => throw UnsupportedError('fse.path');

  @override
  Future<FileSystemEntity> rename(String newPath) =>
      throw UnsupportedError('fse.rename');

  @override
  Future<FileStat> stat() => throw UnsupportedError('fse.stat');

  @override
  FileSystem get fs => throw UnsupportedError('fse.fs');
}

/// Directory mixin.
mixin DirectoryMixin implements Directory {
  @override
  Directory get absolute => throw UnsupportedError('directory.absolute');

  @override
  Future<Directory> create({bool recursive = false}) =>
      throw UnsupportedError('directory.create');

  @override
  Stream<FileSystemEntity> list(
          {bool recursive = false, bool followLinks = true}) =>
      throw UnsupportedError('directory.list');
}
