library tekartik_fs_shim.src.lfs_mixin;

import '../../fs.dart';
import 'dart:async';
import 'dart:convert';

abstract class FileSystemMixin {
  Future<FileSystemEntityType> type(String path, {bool followLinks: true});

  Future<bool> _isType(String path, FileSystemEntityType type_) async {
    return (await type(path, followLinks: true)) == type_;
  }

  // helper
  Future<bool> isFile(String path) => _isType(path, FileSystemEntityType.FILE);

// helper
  Future<bool> isDirectory(String path) =>
      _isType(path, FileSystemEntityType.DIRECTORY);
}

abstract class FileMixin {
  // implemented by IdbFile
  StreamSink<List<int>> openWrite(
      {FileMode mode: FileMode.WRITE, Encoding encoding: UTF8});
  // implemented by IdbFile
  Stream<List<int>> openRead([int start, int end]);
  // implement by IdbFileSystemEntity
  String get path;

  Future<FileMixin> doWriteAsBytes(List<int> bytes,
      {FileMode mode: FileMode.WRITE, bool flush: false}) async {
    var sink = openWrite(mode: mode);
    sink.add(bytes);
    await sink.close();
    return this;
  }

  Future<FileMixin> doWriteAsString(String contents,
      {FileMode mode: FileMode.WRITE,
      Encoding encoding: UTF8,
      bool flush: false}) async {
    return doWriteAsBytes(encoding.encode(contents), mode: mode, flush: flush);
  }

  //@override
  Future<List<int>> readAsBytes() async {
    List<int> content = [];
    var stream = openRead();
    await stream.listen((List<int> data) {
      content.addAll(data);
    }).asFuture();
    return content;
  }

  String _tryDecode(List<int> bytes, Encoding encoding) {
    try {
      return encoding.decode(bytes);
    } catch (_) {
      throw new FormatException(
          "Failed to decode data using encoding '${encoding.name}'", path);
    }
  }

  //@override
  Future<String> readAsString({Encoding encoding: UTF8}) async {
    List<int> content = await readAsBytes();
    if (content != null) {
      return _tryDecode(content, encoding);
    }
    return null;
  }
}