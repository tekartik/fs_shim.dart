import 'dart:math';
import 'dart:typed_data';

import 'package:fs_shim/src/common/bytes_utils.dart';
import 'package:fs_shim/src/common/fs_random_access_file_none.dart';
import 'package:fs_shim/src/common/import.dart';
import 'package:fs_shim/src/idb/idb_file_system.dart';
import 'package:fs_shim/src/idb/idb_file_system_storage.dart';
import 'package:fs_shim/src/idb/idb_paging.dart';
import 'package:idb_shim/idb.dart' as idb;

import 'idb_file_access.dart';

/// Io RandomAccessFile implementation.
class RandomAccessFileIdb
    with DefaultRandomAccessFileMixin, FileAccessIdbMixin {
  /// Idb implementation
  RandomAccessFileIdb(
      {required File file, required Node fileEntity, required FileMode mode}) {
    // set correct position in append mode
    accessPosition = mode == FileMode.append ? fileEntity.fileSize : 0;
    accessFileSize = fileEntity.fileSize;
    accessMaxFileSize = accessFileSize;
    this.file = file;
    initialFileEntity = fileEntity;
    this.fileEntity = fileEntity;
    this.mode = mode;
  }

  RandomAccessFileIdb get _me => this;

  @override
  Future<void> close() async {
    try {
      await flushPending(close: true);
    } catch (e) {
      print('flush failed $e');
    }
  }

  /// Update data.
  Future<void> txnUpdateDataV2(
      idb.Transaction txn, List<FilePartIdb> list) async {
    fileEntity = await storage.txnUpdateFileDataV2(
      txn,
      fileEntity,
      list,
    );
  }

  /// Flush pending items
  Future<void> txnFlushPending({bool close = false}) async {
    if (fileEntity.hasPageSize) {
      if (pending.isNotEmpty) {}
    }
  }

  /// Flush pending items
  Future<void> flushPending({bool close = false}) async {
    if (fileEntity.hasPageSize) {
      if (pending.isNotEmpty || close) {
        await flushLock.synchronized(() async {
          if (pending.isNotEmpty || close) {
            var txn = fsIdb.db!.transactionList(
                [treeStoreName, partStoreName], idb.idbModeReadWrite);
            var list = pending
                .map((e) => e.list)
                .expand((element) => element)
                .toList()
              ..sort((part1, part2) => part1.index - part2.index);
            try {
              await txnUpdateDataV2(txn, list);

              if (close) {
                await storage.txnStoreClearRemainingV2(
                    txn.objectStore(partStoreName),
                    initialFileEntity,
                    fileEntity,
                    newEntityMaxFileSize: accessMaxFileSize);
              }
            } catch (e) {
              if (isDebug) {
                print('flush error $e');
              }
              rethrow;
            } finally {
              pending.clear();
            }
          }
        });
      }
    }
  }

  @override
  Future<RandomAccessFile> flush() async {
    await flushPending();
    // Do nothing
    // throw UnimplementedError('missing flush');
    return _me;
  }

  @override
  Future<int> length() async {
    return await positionLock.synchronized(() async {
      await flushPending();
      /* do not read for now
    var txn = database.transaction(treeStoreName, idb.idbModeReadOnly);
    fileEntity = await storage.nodeFromNode(
        txn.objectStore(treeStoreName), file, fileEntity);*/
      return accessFileSize;
    });
  }

  @override
  String get path => file.path;

  @override
  Future<int> position() async {
    return await positionLock.synchronized(() async {
      await flushPending();
      return accessPosition;
    });
  }

  @override
  Future<Uint8List> read(int count) async {
    return await positionLock.synchronized(() async {
      await flushPending();

      var buffer = Uint8List(min(count, fileEntity.fileSize - accessPosition));
      var readCount = await doReadInto(buffer, 0, buffer.length);
      if (readCount < buffer.length) {
        buffer = buffer.sublist(0, readCount);
      }
      return buffer;
    });
  }

  @override
  Future<int> readByte() async {
    return (await read(1)).firstWhere((element) => true, orElse: () => -1);
  }

  @override
  Future<int> readInto(List<int> buffer, [int start = 0, int? end]) async {
    return await positionLock.synchronized(() async {
      await flushPending();
      return await doReadInto(buffer, start, end ?? buffer.length);
    });
  }

  /// Do read into buffer from [accessPosition] writing at bytes starting at [start] ending at [end]
  Future<int> doReadInto(List<int> buffer, int start, int end) async {
    if (fileEntity.hasPageSize) {
      var bufferEnd = end;
      var positionStart = accessPosition;
      var startPositionInPage = filePartHelper.getPositionInPage(positionStart);
      var positionEnd =
          min(positionStart + (bufferEnd - start), fileEntity.fileSize);
      var startIndex = filePartHelper.pageIndexFromPosition(positionStart);
      var partIndexRead = startIndex - 1;
      var first = true;
      var count = 0;
      var expectedCount = positionEnd - positionStart;
      if (expectedCount <= 0) {
        return 0;
      }
      var txn = database.transactionList([partStoreName], idb.idbModeReadOnly);

      await txn
          .objectStore(partStoreName)
          .openCursor(
              range: filePartHelper.getPartsRange(
                  fileId, positionStart, positionEnd),
              autoAdvance: true)
          .listen((event) {
        // stat
        stat.getCount++;
        var ref = FilePartRef.fromKey(event.key);
        if (++partIndexRead != ref.index) {
          throw StateError('Corrupted content $partIndexRead vs ${ref.index}');
        }
        var bytes = filePartIndexCursorPartContent(event);
        if (first) {
          first = false;
          if (startPositionInPage > 0) {
            bytes = bytes.sublist(startPositionInPage);
          }
          first = false;
        }

        var total = count + bytes.length;
        if (total > expectedCount) {
          // truncate (last)
          bytes = bytes.sublist(0, expectedCount - count);
        }
        if (bytes.isNotEmpty) {
          /// Append
          buffer.setAll(start + count, bytes);
          count += bytes.length;
        }
        if (debugIdbShowLogs) {
          print('cursor reading $ref');
        }
      }).asFuture<void>();
      accessPosition += count;
      return count;
    } else {
      var txn = database.writeAllTransactionList();

      var result =
          await fsIdb.txnReadCheckNodeFileContent(txn, file, fileEntity);
      fileEntity = result.entity;
      var bytes = result.content;
      var remaining = bytes.length - accessPosition;
      if (remaining < 0) {
        return 0;
      }
      var length = min(end - start, remaining);
      var newPosition = accessPosition + length;
      buffer.setAll(start, bytes.sublist(accessPosition, newPosition));
      accessPosition = newPosition;
      return length;
    }
  }

  @override
  Future<RandomAccessFile> setPosition(int position) async {
    return await positionLock.synchronized(() async {
      accessPosition = position;
      return _me;
    });
  }

  @override
  Future<RandomAccessFile> truncate(int length) async {
    return await positionLock.synchronized(() async {
      if (fileEntity.hasPageSize) {
        if (length > accessFileSize) {
          // Add blank data
          accessPosition = accessFileSize;
          await doWriteBuffer(Uint8List(length - accessFileSize));
        }

        await flushPending();
        // Truncate
        // Update accessFileSize fo (no cleanup)
        if (length < accessFileSize) {
          var txn = database.transaction(treeStoreName, idb.idbModeReadWrite);

          fileEntity = await storage.txnUpdateFileMetaSize(txn, fileEntity,
              size: length);
          accessFileSize = length;
        }
        // Keep position
        // await fsIdb.txnWriteNodeFileContent(txn, fileEntity, bytes);
      } else {
        var txn = database.writeAllTransactionList();
        var result =
            await fsIdb.txnReadCheckNodeFileContent(txn, file, fileEntity);
        fileEntity = result.entity;
        var bytes = result.content;

        if (length != bytes.length) {
          if (length < bytes.length) {
            bytes = bytes.sublist(0, length);
          } else {
            var bytesBuilder = BytesBuilder();
            bytesBuilder.add(bytes);
            bytesBuilder
                .add(List.generate(length - bytes.length, (index) => 0));
            bytes = bytesBuilder.toBytes();
          }
          fileEntity =
              await fsIdb.txnWriteNodeFileContent(txn, fileEntity, bytes);
          accessFileSize = fileEntity.fileSize;
        }
      }
      return _me;
    });
  }

  @override
  Future<RandomAccessFile> writeByte(int value) async {
    return await writeFrom([value]);
  }

  /// Pending file parts
  final pending = <FilePartResult>[];

  @override
  Future<RandomAccessFile> writeFrom(List<int> buffer,
      [int start = 0, int? end]) async {
    return await positionLock.synchronized(() async {
      var result = await doWriteFrom(buffer, start, end ?? buffer.length);
      if (!noAsyncFlush) {
        asyncFlush();
      }
      return result;
    });
  }

  /// Flush at the next async.
  void asyncFlush() {
    asyncAction(() async {
      try {
        await flushPending();
      } catch (e) {
        print('flushPending failed $e');
      }
    });
  }

  /// Write full buffer
  Future<RandomAccessFile> doWriteBuffer(List<int> buffer) =>
      doWriteFrom(buffer, 0, buffer.length);

  /// Do write content at current position, skippend buffer from start
  Future<RandomAccessFile> doWriteFrom(
      List<int> buffer, int start, int end) async {
    idb.Transaction? txn;
    if (fileEntity.hasPageSize) {
      // Add blank if needed
      if (accessPosition > accessFileSize) {
        var blankSize = accessPosition - accessFileSize;
        // add blank
        accessPosition = accessFileSize;
        await doWriteBuffer(Uint8List(blankSize));
      }

      var result = filePartHelper.getFileParts(
          bytes: buffer,
          start: start,
          end: end,
          position: accessPosition,
          all: true);
      pending.add(result);
      accessPosition = result.position;
      accessFileSize = max(accessPosition, accessFileSize);
      accessMaxFileSize = max(accessMaxFileSize, accessFileSize);
      return _me;
    } else {
      try {
        txn = fsIdb.writeAllTransactionList();

        var result =
            await fsIdb.txnReadCheckNodeFileContent(txn, file, fileEntity);
        fileEntity = result.entity;
        var bytes = result.content;
        var bytesBuilder = BytesBuilder();
        if (accessPosition > 0) {
          if (bytes.length >= accessPosition) {
            bytesBuilder.add(bytes.sublist(0, accessPosition));
          } else {
            bytesBuilder.add(bytes);
            // add blank
            bytesBuilder.add(Uint8List(accessPosition - bytes.length));
          }
        }
        bytesBuilder.add(buffer.sublist(start, end));
        accessPosition = bytesBuilder.length;
        if (accessPosition < bytes.length) {
          bytesBuilder.add(bytes.sublist(accessPosition));
        }
        var newBytes = bytesBuilder.toBytes();

        fileEntity =
            await fsIdb.txnWriteNodeFileContent(txn, fileEntity, newBytes);
        accessFileSize = fileEntity.fileSize;
        return _me;
      } finally {
        await txn?.completed;
      }
    }
  }

  @override
  Future<RandomAccessFile> writeString(String string,
      {Encoding encoding = utf8}) async {
    var bytes = asUint8List(encoding.encode(string));
    return await writeFrom(bytes);
  }
}
