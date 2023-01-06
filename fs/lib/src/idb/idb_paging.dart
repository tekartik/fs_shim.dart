// ignore_for_file: public_member_api_docs

import 'dart:math';
import 'dart:typed_data';

import 'package:fs_shim/src/common/bytes_utils.dart';

/// An idb part to update.
class StreamPartIdb {
  /// Source bytes
  final Uint8List bytes;

  /// Part index.
  final int index;

  /// start to copy inside existing part (default 0)
  final int start;

  /// end to copy inside existing part (default end)
  final int? end;

  /// An idb part to update.
  StreamPartIdb(
      {required this.bytes, required this.index, this.start = 0, this.end});
}

class StreamPartResult {
  final int position; // new position

  final List<StreamPartIdb> list;

  StreamPartResult({required this.position, required this.list});
}

class StreamPartHelper {
  final int pageSize;

  StreamPartHelper(this.pageSize);

  /// Add the whole bytes at position
  ///
  /// [all] means include last part
  StreamPartResult getStreamParts(
      {required List<int> bytes, required int position, bool all = false}) {
    // index in bytes
    var index = 0;
    var newPosition = position;
    var list = <StreamPartIdb>[];
    while (true) {
      var remaining = bytes.length - index;
      if (remaining <= 0) {
        break;
      }

      var positionInPage = newPosition % pageSize;
      var pageIndex = pageIndexFromPosition(newPosition);

      var neededToFillPage = pageSize - positionInPage;
      if (remaining >= neededToFillPage || all) {
        // for all
        var adding = min(remaining, neededToFillPage);
        list.add(StreamPartIdb(
            bytes: asUint8List(bytes.sublist(index, index + adding)),
            index: pageIndex,
            start: positionInPage));
        newPosition += adding;
        index += adding;
      } else {
        // Not full
        break;
      }
    }
    return StreamPartResult(position: newPosition, list: list);
  }

  int pageIndexFromPosition(int position) => position ~/ pageSize;
  int pageCountFromSize(int size) =>
      pageCountFromSizeAndPageSize(size, pageSize);
}

/// Page count from size and page size.
int pageCountFromSizeAndPageSize(int size, int pageSize) =>
    pageSize == 0 ? 1 : ((((size - 1) ~/ pageSize)) + 1);
