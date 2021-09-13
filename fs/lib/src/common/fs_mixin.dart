library fs_shim.src.lfs_mixin;

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:fs_shim/fs.dart';
import 'package:fs_shim/src/common/bytes_utils.dart';

/// FileSystem mixin
abstract class FileSystemMixin implements FileSystem {
  @override
  Future<FileSystemEntityType> type(String? path, {bool followLinks = true});

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
}

/// File mixin
abstract class FileMixin implements File {
  @override
  StreamSink<List<int>> openWrite(
      {FileMode mode = FileMode.write, Encoding encoding = utf8});

  @override
  Stream<Uint8List> openRead([int? start, int? end]);

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
