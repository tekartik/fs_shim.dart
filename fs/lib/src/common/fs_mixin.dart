library fs_shim.src.lfs_mixin;

import 'dart:async';
import 'dart:convert';

import 'package:dart2_constant/convert.dart' as convert;
import 'package:fs_shim/fs.dart';

abstract class FileSystemMixin implements FileSystem {
  @override
  Future<FileSystemEntityType> type(String path, {bool followLinks = true});

  Future<bool> _isType(String path, FileSystemEntityType fseType,
      {bool followLinks = true}) async {
    return (await type(path, followLinks: followLinks)) == fseType;
  }

  // helper
  @override
  Future<bool> isFile(String path) => _isType(path, FileSystemEntityType.file);

  // helper
  @override
  Future<bool> isDirectory(String path) =>
      _isType(path, FileSystemEntityType.directory);

  // helper
  // do not follow links for link check
  @override
  Future<bool> isLink(String path) =>
      _isType(path, FileSystemEntityType.link, followLinks: false);
}

abstract class FileMixin {
  // implemented by IdbFile
  StreamSink<List<int>> openWrite(
      {FileMode mode = FileMode.write, Encoding encoding = convert.utf8});

  // implemented by IdbFile
  Stream<List<int>> openRead([int start, int end]);

  // implemented by IdbFileSystemEntity
  String get path;

  Future<FileMixin> doWriteAsBytes(List<int> bytes,
      {FileMode mode = FileMode.write, bool flush = false}) async {
    var sink = openWrite(mode: mode);
    sink.add(bytes);
    await sink.close();
    return this;
  }

  Future<FileMixin> doWriteAsString(String contents,
          {FileMode mode = FileMode.write,
          Encoding encoding = convert.utf8,
          bool flush = false}) =>
      doWriteAsBytes(encoding.encode(contents), mode: mode, flush: flush);

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
      throw FormatException(
          "Failed to decode data using encoding '${encoding.name}'", path);
    }
  }

  //@override
  Future<String> readAsString({Encoding encoding = convert.utf8}) async {
    List<int> content = await readAsBytes();
    if (content != null) {
      return _tryDecode(content, encoding);
    }
    return null;
  }
}
