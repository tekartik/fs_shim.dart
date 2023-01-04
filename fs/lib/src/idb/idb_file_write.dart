import 'dart:typed_data';

import 'package:fs_shim/fs_idb.dart';
import 'package:fs_shim/fs_shim.dart' as fs;
import 'package:fs_shim/src/common/bytes_utils.dart';
import 'package:fs_shim/src/common/import.dart';
import 'package:fs_shim/src/common/memory_sink.dart';
import 'package:idb_shim/idb.dart' as idb;

import 'idb_file_system.dart';
import 'idb_file_system_storage.dart';

/// Write in transaction controller.
class TxnWriteStreamSinkIdb extends MemorySink {
  /// The file system.
  final IdbFileSystem _fs;

  /// Transaction.
  final idb.Transaction txn;

  /// File entity.
  final Node fileEntity;

  /// The internal storage
  IdbFileSystemStorage get storage => _fs.storage;

  /// The open mode (write or append)
  fs.FileMode mode;

  /// Write sink in transaction.
  TxnWriteStreamSinkIdb(this._fs, this.txn, this.fileEntity, this.mode)
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
        bytesBuilder.add(await _fs.txnReadNodeFileContent(txn, entity));
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
