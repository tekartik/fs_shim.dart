import 'dart:typed_data';

import 'package:fs_shim/src/common/bytes_utils.dart';
import 'package:fs_shim/src/common/import.dart';
import 'package:idb_shim/idb.dart' as idb;

import 'idb_file_system.dart';
import 'idb_file_system_storage.dart';

/// Read data stream controller in a transaction.
///
/// Must be read, right away/
class TxnNodeDataReadStreamCtlr {
  /// File entity.
  final Node fileEntity;

  /// Transaction.
  final idb.Transaction txn;

  /// File system.
  final FileSystemIdb fs;

  /// Start of read.
  int? start;

  /// End of read.
  int? end;

  late StreamController<Uint8List> _ctlr;

  /// Read in transaction controller.
  TxnNodeDataReadStreamCtlr(
      this.fs, this.txn, this.fileEntity, this.start, this.end) {
    _ctlr = StreamController(
        sync: true,
        onListen: () async {
          var content = await fs.txnReadNodeFileContent(txn, fileEntity);

          // get existing content
          //store = txn.objectStore(fileStoreName);
          //var content = (await store.getObject(entity.id!) as List?)?.cast<int>();
          if (content.isNotEmpty) {
            // All at once!
            if (start != null) {
              content = content.sublist(start!, end);
            }
            _ctlr.add(anyListAsUint8List(content));
          }
          // devPrint('txnRead done (${content.length})');
          await _ctlr.close();
        },
        onCancel: () {
          // devPrint('txnRead onCancel');
          // no await here, otherwise the transaction becomes inactive
          _ctlr.close();
        });
  }

  /// Stream
  Stream<Uint8List> get stream => _ctlr.stream;
}
