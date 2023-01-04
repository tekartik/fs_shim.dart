import 'dart:math';
import 'dart:typed_data';

import 'package:fs_shim/src/common/bytes_utils.dart';
import 'package:fs_shim/src/common/fs_random_access_file_none.dart';
import 'package:fs_shim/src/common/import.dart';
import 'package:fs_shim/src/idb/idb_file_system.dart';
import 'package:fs_shim/src/idb/idb_file_system_storage.dart';

/// Io RandomAccessFile implementation.
class RandomAccessFileIdb with DefaultRandomAccessFileMixin {
  FileSystemIdb get _fs => file.fs as FileSystemIdb;

  /// The opened file
  final File file;

  /// Local file entity, updated on write
  Node fileEntity;

  /// The open mode
  final FileMode mode;

  /// Internal storage
  // IdbFileSystemStorage get _storage => _fs.storage;

  /// initial position
  var _position = 0;

  /// Idb implementation
  RandomAccessFileIdb(
      {required this.file, required this.fileEntity, required this.mode});

  RandomAccessFileIdb get _me => this;

  @override
  Future<void> close() async {
    try {
      await flush();
    } catch (e) {
      print('flush failed $e');
    }
  }

  @override
  Future<RandomAccessFile> flush() async {
    // Do nothing
    // throw UnimplementedError('missing flush');
    return _me;
  }

  @override
  Future<int> length() async {
    return fileEntity.fileSize;
  }

  @override
  String get path => file.path;

  @override
  Future<int> position() async => _position;

  @override
  Future<Uint8List> read(int count) async {
    var txn = _fs.writeAllTransactionList();
    //devPrint('read(index $_position, $count bytes) $fileEntity');
    var bytes = await _fs.txnReadNodeFileContent(txn, fileEntity);

    var remaining = bytes.length - _position;
    if (remaining < 0 || count == 0) {
      return Uint8List(0);
    }
    var bytesBuilder = BytesBuilder();
    var length = min(remaining, count);
    bytesBuilder.add(bytes.sublist(_position, _position + length));
    _position += length;
    return bytesBuilder.toBytes();
  }

  @override
  Future<int> readByte() async {
    return (await read(1)).firstWhere((element) => true, orElse: () => -1);
  }

  @override
  Future<int> readInto(List<int> buffer, [int start = 0, int? end]) async {
    var txn = _fs.writeAllTransactionList();
    var bytes = await _fs.txnReadNodeFileContent(txn, fileEntity);
    var remaining = bytes.length - _position;
    if (remaining < 0) {
      return 0;
    }
    var length = min((end ?? buffer.length) - start, remaining);
    var newPosition = _position + length;
    buffer.setAll(start, bytes.sublist(_position, newPosition));
    _position = newPosition;
    return length;
  }

  @override
  Future<RandomAccessFile> setPosition(int position) async {
    _position = position;
    return this;
  }

  @override
  Future<RandomAccessFile> truncate(int length) async {
    var txn = _fs.writeAllTransactionList();
    var bytes = await _fs.txnReadNodeFileContent(txn, fileEntity);
    if (length != bytes.length) {
      if (length < bytes.length) {
        bytes = bytes.sublist(0, length);
      } else {
        var bytesBuilder = BytesBuilder();
        bytesBuilder.add(bytes);
        bytesBuilder.add(List.generate(length - bytes.length, (index) => 0));
        bytes = bytesBuilder.toBytes();
      }
      fileEntity = await _fs.txnWriteNodeFileContent(txn, fileEntity, bytes);
    }
    return _me;
  }

  @override
  Future<RandomAccessFile> writeByte(int value) async {
    return await writeFrom([value]);
  }

  @override
  Future<RandomAccessFile> writeFrom(List<int> buffer,
      [int start = 0, int? end]) async {
    //devPrint('write($start to $end): ${logTruncateAny(buffer)}');
    var txn = _fs.writeAllTransactionList();
    var bytes = await _fs.txnReadNodeFileContent(txn, fileEntity);
    var bytesBuilder = BytesBuilder();
    if (_position > 0) {
      if (bytes.length >= _position) {
        bytesBuilder.add(bytes.sublist(0, _position));
      } else {
        bytesBuilder.add(bytes);
        bytesBuilder.add(List.generate(_position - bytes.length, (index) => 0));
      }
    }
    bytesBuilder.add(buffer.sublist(start, end));
    _position = bytesBuilder.length;
    if (_position < bytes.length) {
      bytesBuilder.add(bytes.sublist(_position));
    }

    fileEntity = await _fs.txnWriteNodeFileContent(
        txn, fileEntity, bytesBuilder.toBytes());
    return _me;
  }

  @override
  Future<RandomAccessFile> writeString(String string,
      {Encoding encoding = utf8}) async {
    var bytes = asUint8List(encoding.encode(string));
    return await writeFrom(bytes, _position);
  }
}
