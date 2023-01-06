// ignore_for_file: public_member_api_docs

import 'dart:typed_data';

import 'package:fs_shim/fs_idb.dart';
import 'package:fs_shim/fs_shim.dart' as fs;
import 'package:fs_shim/src/common/bytes_utils.dart';
import 'package:fs_shim/src/common/import.dart';
import 'package:fs_shim/src/common/memory_sink.dart';
import 'package:fs_shim/src/idb/idb_paging.dart';
import 'package:idb_shim/idb.dart' as idb;
import 'package:synchronized/synchronized.dart';

import 'idb_file_system.dart';
import 'idb_file_system_storage.dart';

/// Write in transaction controller.
class TxnWriteStreamSinkIdb extends MemorySink {
  /// The file.
  final fs.File file;

  /// The file system.
  FileSystemIdb get _fs => file.fs as FileSystemIdb;

  /// Transaction.
  final idb.Transaction txn;

  /// File entity.
  final Node fileEntity;

  /// The internal storage
  IdbFileSystemStorage get storage => _fs.storage;

  /// The open mode (write or append)
  fs.FileMode mode;

  /// Write sink in transaction.
  TxnWriteStreamSinkIdb(this.file, this.txn, this.fileEntity, this.mode)
      : super();

  @override
  Future close() async {
    // devPrint('closing write $fileEntity $mode');
    try {
      var entity = fileEntity;

      var existingSize = entity.fileSize;

      // get existing content
      var bytesBuilder = BytesBuilder();
      if (mode == fs.FileMode.write || existingSize == 0) {
        // was created or existing
      } else {
        var result =
            await _fs.txnReadCheckNodeFileContent(txn, file, fileEntity);
        entity = result.entity;
        var bytes = result.content;
        bytesBuilder.add(bytes);
      }

      bytesBuilder.add(this.content);
      var content = bytesBuilder.toBytes();
      if (content.isEmpty) {
        if (existingSize > 0) {
          if (debugIdbShowLogs) {
            print('delete $entity content');
          }
          await _fs.txnDeleteFileContent(txn, entity);
          await storage.txnUpdateFileMetaSize(txn, entity, size: 0);
        }
      } else {
        // devPrint('wrilte all ${content.length}');
        // New in 2020/11/1
        var bytes = anyListAsUint8List(content);

        entity.modified = DateTime.now();
        entity.pageSize = storage.options.expectedPageSize;
        await _fs.txnWriteNodeFileContent(txn, entity, bytes);
      }
    } finally {
      await txn.completed;
    }
  }
}

/// Write stream sink.
class IdbWriteStreamSink extends MemorySink {
  final IdbFileSystem _fs;
  final _lock = Lock();

  IdbFileSystemStorage get storage => _fs.storage;
  final fs.File file;

  fs.FileMode mode;
  var _opened = false;

  /// Only valid once opened.
  late int position;

  /// Only valid once opened.
  late Node initialEntity;

  /// Only valid once opened.
  late Node entity;

  /// Write stream helper
  IdbWriteStreamSink(this._fs, this.file, this.mode) : super();

  /// Flush current stream. paging only for now
  Future<void> flush() async {
    await flushPending(all: true);
  }

  @override
  Future close() async {
    await super.close();

    if (_fs.idbOptions.hasPageSize) {
      await flush();
    } else {
      await _openNodeFile();
      var txn = _fs.db!.writeAllTransactionList();
      try {
        var ctlr = TxnWriteStreamSinkIdb(file, txn, entity, mode);
        ctlr.add(content);
        await ctlr.close();
      } finally {
        await txn.completed;
      }
    }
  }

  /// if [all] is false, flush full entries only
  Future<void> flushPending({bool all = false}) async {
    if (_fs.idbOptions.hasPageSize) {
      if (content.isNotEmpty || all) {
        await _openNodeFile();
        if (entity.hasPageSize) {
          // Is one page full?
          var pageSize = entity.filePageSize;

          // var filled = position % pageSize;
          //var neededToFill = pageSize -
          var helper = StreamPartHelper(pageSize);
          var result = helper.getStreamParts(
              bytes: content, position: position, all: all);
          if (result.list.isNotEmpty) {
            var txn = _fs.db!.transactionList(
                [treeStoreName, partStoreName], idb.idbModeReadWrite);
            try {
              entity = await storage.txnUpdateStreamedFileDataV2(
                  txn, entity, result.list);
            } finally {
              await txn.completed;
            }
          }
        }
      }

      if (content.isEmpty && all) {
        // TODO delete empty?
      }
    }
  }

  /// Open, set entity and position
  Future<void> _openNodeFile() async {
    if (!_opened) {
      await _lock.synchronized(() async {
        if (!_opened) {
          entity = initialEntity = await _fs.openNodeFile(file, mode: mode);
          position = mode == FileMode.append ? entity.fileSize : 0;
          _opened = true;
        }
      });
    }
  }
}
