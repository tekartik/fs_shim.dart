// ignore_for_file: public_member_api_docs

import 'dart:typed_data';

import 'package:fs_shim/src/common/bytes_utils.dart';
import 'package:fs_shim/src/common/import.dart';
import 'package:fs_shim/src/idb/idb_paging.dart';
import 'package:idb_shim/idb.dart' as idb;

import 'idb_file_system.dart';
import 'idb_file_system_storage.dart';

/// Read data stream controller in a transaction.
///
/// Must be read, right away/
class TxnNodeDataReadStreamCtlr {
  /// The opened file.
  final File file;

  /// File entity.
  Node fileEntity;

  /// Transaction.
  final idb.Transaction txn;

  /// File system.
  FileSystemIdb get fs => file.fs as FileSystemIdb;

  /// Start of read.
  int? start;

  /// End of read.
  int? end;

  late StreamController<Uint8List> _ctlr;

  Future<void> txnRead() async {
    try {
      if (fileEntity.hasPageSize) {
        var helper = FilePartHelper(fileEntity.filePageSize);

        var fileId = fileEntity.fileId;
        var start = this.start ?? 0;
        var end = this.end ?? fileEntity.fileSize;
        var startPositionInPage = helper.getPositionInPage(start);
        var partIndex = -1;
        var first = true;
        var expectedCount = end - start;
        var count = 0;
        if (end > start) {
          await txn
              .objectStore(partStoreName)
              .openCursor(
                  range: helper.getPartsRange(fileId, start, end),
                  autoAdvance: true)
              .listen((event) {
            var ref = FilePartRef.fromKey(event.key);
            if (++partIndex != ref.index) {
              throw StateError('Corrupted content');
            }
            var bytes = filePartIndexCursorPartContent(event);
            if (first) {
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
              count += bytes.length;
              _ctlr.add(bytes);
            }
          }).asFuture();
        }
      } else {
        var result =
            await fs.txnReadCheckNodeFileContent(txn, file, fileEntity);
        fileEntity = result.entity;
        var content = result.content;

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
      }
      // devPrint('txnRead done (${content.length})');
      await _ctlr.close();
    } catch (error) {
      _ctlr.addError(error);
    }
  }

  /// Read in transaction controller.
  TxnNodeDataReadStreamCtlr(
      this.file, this.txn, this.fileEntity, this.start, this.end) {
    _ctlr = StreamController(
        sync: true,
        onCancel: () {
          // devPrint('txnRead onCancel');
          // no await here, otherwise the transaction becomes inactive
          _ctlr.close();
        });
    txnRead();
  }

  /// Stream
  Stream<Uint8List> get stream => _ctlr.stream;
}

class IdbReadStreamCtlr {
  FileSystemIdb get _fs => file.fs as FileSystemIdb;
  final File file;
  int? start;
  int? end;

  IdbFileSystemStorage get storage => _fs.storage;
  late StreamController<Uint8List> _ctlr;

  IdbReadStreamCtlr(this.file, this.start, this.end) {
    _ctlr = StreamController(sync: true);

    // put data
    Future<void> readAll() async {
      await _fs.idbReady;
      final txn = _fs.db!.readAllTransactionList();
      var treeStore = txn.objectStore(treeStoreName);

      try {
        // Try to find the file if it exists
        final segments = getSegments(file.path);

        var entity =
            await _fs.txnOpenNode(treeStore, segments, mode: FileMode.read);

        var ctlr = TxnNodeDataReadStreamCtlr(file, txn, entity, start, end);
        ctlr.stream.listen((event) {
          _ctlr.add(event);
        }, onDone: () {
          _ctlr.close();
        }, onError: (Object e) {
          _ctlr.addError(e);
        });
      } catch (e) {
        _ctlr.addError(e);
      } finally {
        await txn.completed;
      }
    }

    _ctlr = StreamController(
        sync: true,
        onListen: () {
          readAll();
        });
  }

  Stream<Uint8List> get stream => _ctlr.stream;
}
