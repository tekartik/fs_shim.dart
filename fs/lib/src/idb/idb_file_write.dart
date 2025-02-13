// ignore_for_file: public_member_api_docs

import 'dart:typed_data';

import 'package:fs_shim/fs_idb.dart';
import 'package:fs_shim/fs_shim.dart' as fs;
import 'package:fs_shim/src/common/bytes_utils.dart';
import 'package:fs_shim/src/common/import.dart';
import 'package:fs_shim/src/common/memory_sink.dart';
import 'package:fs_shim/src/idb/idb_paging.dart';
import 'package:idb_shim/idb.dart' as idb;
import 'package:meta/meta.dart';
import 'package:synchronized/synchronized.dart';

import 'idb_file_access.dart';
import 'idb_file_system.dart';
import 'idb_file_system_storage.dart';

/// Write in transaction controller. v1 all in memory.
class TxnWriteStreamSinkIdb extends MemorySink with FileAccessIdbMixin {
  /// Transaction.
  final idb.Transaction txn;

  /// Write sink in transaction.
  TxnWriteStreamSinkIdb(
    File file,
    this.txn,
    Node fileEntity,
    FileMode mode, {
    required Node initialFileEntity,
  }) : super() {
    this.initialFileEntity = initialFileEntity;
    this.fileEntity = fileEntity;
    this.file = file;
    this.mode = mode;
  }

  @override
  Future close() async {
    // devPrint('closing write $fileEntity $mode');
    try {
      //var existingSize = fileEntity.fileSize;

      // get existing content
      var bytesBuilder = BytesBuilder();
      if (mode == fs.FileMode.write || initialFileEntity.fileSize == 0) {
        // was created or existing
      } else {
        var result = await fsIdb.txnReadCheckNodeFileContent(
          txn,
          file,
          fileEntity,
        );
        fileEntity = result.entity;
        var bytes = result.content;
        bytesBuilder.add(bytes);
      }

      bytesBuilder.add(this.content);
      var content = bytesBuilder.toBytes();
      if (content.isEmpty) {
        if (initialFileEntity.size != 0) {
          if (debugIdbShowLogs) {
            // ignore: avoid_print
            print('delete $fileEntity content');
          }
          await fsIdb.txnDeleteFileContent(txn, fileEntity);
          await storage.txnUpdateFileMetaSize(txn, fileEntity, size: 0);
        }
      } else {
        // devPrint('wrilte all ${content.length}');
        // New in 2020/11/1
        var bytes = anyListAsUint8List(content);

        fileEntity.modified = DateTime.now();
        fileEntity.pageSize = storage.options.expectedPageSize;
        await fsIdb.txnWriteNodeFileContent(txn, fileEntity, bytes);
      }
    } finally {
      await txn.completed;
    }
  }
}

/// Write stream sink.
class IdbWriteStreamSink extends MemorySink with FileAccessIdbMixin {
  final _openLock = Lock();

  var _opened = false;
  @visibleForTesting
  bool get opened => _opened;

  /// Only valid once opened.
  late int position;

  /// Write stream helper
  IdbWriteStreamSink(File file, FileMode mode) : super() {
    this.file = file;
    this.mode = mode;
  }

  /// Flush current stream. paging only for now
  Future<void> flush({bool close = false}) async {
    await flushPending(all: true, close: close);
  }

  /// Asynchronous flush
  /// Always postpone
  void asyncFlush() {
    asyncAction(() async {
      try {
        if (debugIdbShowLogs) {
          // ignore: avoid_print
          print('auto flush');
        }
        await flushPending();
      } catch (e) {
        // ignore: avoid_print
        print('flushPending failed $e');
      }
    });
  }

  @override
  void add(List<int> data) {
    super.add(data);
    asyncFlush();
  }

  @override
  Future close() async {
    await super.close();

    if (fsIdb.idbOptions.hasPageSize) {
      await flush(close: true);
    } else {
      await _openNodeFile();
      var txn = database.writeAllTransactionList();
      try {
        var ctlr = TxnWriteStreamSinkIdb(
          file,
          txn,
          fileEntity,
          mode,
          initialFileEntity: initialFileEntity,
        );
        ctlr.add(content);
        await ctlr.close();
      } finally {
        await txn.completed;
      }
    }
  }

  /// if [all] is false, flush full entries only
  Future<void> flushPending({bool all = false, bool close = false}) async {
    if (fsIdb.idbOptions.hasPageSize) {
      if (content.isNotEmpty || all || close) {
        await flushLock.synchronized(() async {
          if (content.isNotEmpty || all || close) {
            await _openNodeFile();
            // devPrint('flushPending($all, $close) $initialEntity, $entity');
            if (fileEntity.hasPageSize) {
              // Is one page full?
              var pageSize = fileEntity.filePageSize;

              // var filled = position % pageSize;
              //var neededToFill = pageSize -
              var helper = FilePartHelper(pageSize);
              var result = helper.getFileParts(
                bytes: content,
                position: position,
                all: all,
              );
              if (result.list.isNotEmpty) {
                var txn = database.transactionList([
                  treeStoreName,
                  partStoreName,
                ], idb.idbModeReadWrite);
                try {
                  fileEntity = await storage.txnUpdateFileDataV2(
                    txn,
                    fileEntity,
                    result.list,
                  );
                  var length = result.position - position;
                  // Truncate
                  content = content.sublist(length);
                  position = result.position;

                  if (close) {
                    await storage.txnStoreClearRemainingV2(
                      txn.objectStore(partStoreName),
                      initialFileEntity,
                      fileEntity,
                    );
                  }
                } finally {
                  await txn.completed;
                }
              } else {
                if (close) {
                  if (storage.needClearRemainingV2(
                    initialFileEntity,
                    fileEntity,
                  )) {
                    var txn = database.transaction(
                      partStoreName,
                      idb.idbModeReadWrite,
                    );
                    try {
                      await storage.txnStoreClearRemainingV2(
                        txn.objectStore(partStoreName),
                        initialFileEntity,
                        fileEntity,
                      );
                    } finally {
                      await txn.completed;
                    }
                  }
                }
                // devPrint('Are we done? closing: $close');
              }
            }
          }
        });
      }
    }
  }

  /// Open, set fileEntity and position
  Future<void> _openNodeFile() async {
    if (!_opened) {
      await _openLock.synchronized(() async {
        if (!_opened) {
          initialFileEntity = await fsIdb.openNodeFile(file, mode: mode);

          position = mode == FileMode.append ? initialFileEntity.fileSize : 0;

          // Truncate at position right away.
          fileEntity = initialFileEntity.clone(size: position);

          _opened = true;
        }
      });
    }
  }
}

/*
/// Write stream sink.
class TxnIdbWriteStreamHelper {
  FileSystemIdb get _fs => file.fs as FileSystemIdb;
  final MemorySink sink;
  final idb.Transaction txn;
  final _openLock = Lock();
  final _flushLock = Lock();

  IdbFileSystemStorage get storage => _fs.storage;
  final fs.File file;

  fs.FileMode mode;
  var _opened = false;

  /// Only valid once opened.
  late int position;

  /// Only valid once opened.
  late Node initialEntity;
  Node get existingEntity => initialEntity;

  /// Only valid once opened.
  late Node fileEntity;

  /// Write stream helper
  TxnIdbWriteStreamHelper(this.txn, this.file, this.mode,
      {required this.initialEntity, required this.sink})
      : super();

  /// Flush current stream. paging only for now
  Future<void> flush({bool close = false}) async {
    await flushPending(all: true, close: close);
  }

  Future<void> writeAll() async {
    var bytesBuilder = BytesBuilder();
    if (mode == fs.FileMode.write || existingEntity.fileSize == 0) {
      // was created or existing
    } else {
      var result = await _fs.txnReadCheckNodeFileContent(txn, file, fileEntity);
      fileEntity = result.fileEntity;
      var bytes = result.content;
      bytesBuilder.add(bytes);
    }

    bytesBuilder.add(this.content);
    var content = bytesBuilder.toBytes();
    if (content.isEmpty) {
      if (existingEntity.size != 0) {
        if (debugIdbShowLogs) {
          print('delete $entity content');
        }
        await _fs.txnDeleteFileContent(txn, fileEntity);
        await storage.txnUpdateFileMetaSize(txn, fileEntity, size: 0);
      }
    } else {
      // devPrint('wrilte all ${content.length}');
      // New in 2020/11/1
      var bytes = anyListAsUint8List(content);

      fileEntity.modified = DateTime.now();
      fileEntity.pageSize = storage.options.expectedPageSize;
      await _fs.txnWriteNodeFileContent(txn, fileEntity, bytes);
    }
  }

  void asyncFlush() {
    Future.value().then((_) {
      flushPending();
    });
  }

  @override
  void add(List<int> data) {
    super.add(data);
    asyncFlush();
  }

  @override
  Future close() async {
    await super.close();

    if (_fs.idbOptions.hasPageSize) {
      await flush(close: true);
    } else {
      await _openNodeFile();
      var txn = _fs.db!.writeAllTransactionList();
      try {
        var ctlr = TxnWriteStreamSinkIdb(file, txn, fileEntity, mode,
            existingEntity: initialEntity);
        ctlr.add(content);
        await ctlr.close();
      } finally {
        await txn.completed;
      }
    }
  }

  /// if [all] is false, flush full entries only
  Future<void> flushPending({bool all = false, bool close = false}) async {
    if (_fs.idbOptions.hasPageSize) {
      await _flushLock.synchronized(() async {
        if (content.isNotEmpty || all) {
          await _openNodeFile();
          // devPrint('flushPending($all, $close) $initialEntity, $entity');
          if (fileEntity.hasPageSize) {
            // Is one page full?
            var pageSize = fileEntity.filePageSize;

            // var filled = position % pageSize;
            //var neededToFill = pageSize -
            var helper = StreamPartHelper(pageSize);
            var result = helper.getStreamParts(
                bytes: content, position: position, all: all);
            if (result.list.isNotEmpty) {
              var txn = _fs.db!.transactionList(
                  [treeStoreName, partStoreName], idb.idbModeReadWrite);
              try {
                fileEntity = await storage.txnUpdateStreamedFileDataV2(
                  txn,
                  fileEntity,
                  result.list,
                );
                var length = result.position - position;
                // Truncate
                content = content.sublist(length);
                position = result.position;

                if (close) {
                  await storage.txnStoreClearRemainingV2(
                      txn.objectStore(partStoreName), initialEntity, fileEntity);
                }
              } finally {
                await txn.completed;
              }
            } else {
              if (close) {
                if (storage.needClearRemainingV2(initialEntity, fileEntity)) {
                  var txn =
                      _fs.db!.transaction(partStoreName, idb.idbModeReadWrite);
                  try {
                    await storage.txnStoreClearRemainingV2(
                        txn.objectStore(partStoreName), initialEntity, fileEntity);
                  } finally {
                    await txn.completed;
                  }
                }
              }
              // devPrint('Are we done? closing: $close');
            }
          }
        }
      });
    }
  }

  /// Open, set fileEntity and position
  Future<void> _openNodeFile() async {
    if (!_opened) {
      await _openLock.synchronized(() async {
        if (!_opened) {
          initialEntity = await _fs.openNodeFile(file, mode: mode);

          position = mode == FileMode.append ? initialEntity.fileSize : 0;

          // Truncate at position right away.
          fileEntity = initialEntity.clone(size: position);

          _opened = true;
        }
      });
    }
  }
}
*/
