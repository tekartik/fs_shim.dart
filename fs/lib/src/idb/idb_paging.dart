// ignore_for_file: public_member_api_docs

import 'dart:math';
import 'dart:typed_data';

import 'package:fs_shim/src/common/bytes_utils.dart';
import 'package:idb_shim/idb.dart' as idb;

import 'idb_file_system_storage.dart';

/// An idb part to update.
class FilePartIdb {
  /// Source bytes (trimmed)
  final Uint8List bytes;

  /// Part index.
  final int index;

  /// start to copy inside existing part (default 0)
  ///
  /// This is not a index in bytes.
  final int start;

  int get end => start + bytes.lengthInBytes;

  /// An idb part to update.
  FilePartIdb({required this.bytes, required this.index, this.start = 0});

  @override
  String toString() => '[$index]: $start (size ${bytes.length})';
}

class FilePartResult {
  final int position; // new position

  final List<FilePartIdb> list;

  FilePartResult({required this.position, required this.list});
  @override
  String toString() => 'pos: $position $list';
}

class FilePartHelper {
  final int pageSize;

  FilePartHelper(this.pageSize);

  int getPositionInPage(int position) => position % pageSize;

  idb.KeyRange getPartsRange(int fileId, int start, int end) {
    var indexStart = pageIndexFromPosition(start);
    var indexEnd = endPageIndexFromPosition(end);
    return idb.KeyRange.bound(
      toFilePartIndexKey(fileId, indexStart),
      toFilePartIndexKey(fileId, indexEnd),
      false,
      true,
    );
  }

  /// Add the whole bytes at position
  ///
  /// [all] means include last part
  ///
  /// [start] index int [bytes]
  /// [end] index
  ///
  /// [position] is the absolute file index.
  FilePartResult getFileParts({
    required List<int> bytes,
    int position = 0,
    int start = 0,
    bool all = false,
    int? end,
  }) {
    // index in bytes
    var srcIndex = start;
    end ??= bytes.length;
    var newPosition = position;
    var list = <FilePartIdb>[];
    while (true) {
      var remaining = end - srcIndex;
      if (remaining <= 0) {
        break;
      }

      var positionInPage = getPositionInPage(newPosition);
      var pageIndex = pageIndexFromPosition(newPosition);

      var neededToFillPage = pageSize - positionInPage;
      if (remaining >= neededToFillPage || all) {
        // for all
        var adding = min(remaining, neededToFillPage);
        var buffer = asUint8List(bytes.sublist(srcIndex, srcIndex + adding));
        var filePart = FilePartIdb(
          bytes: buffer,
          index: pageIndex,
          start: positionInPage,
        );
        list.add(filePart);
        newPosition += adding;
        srcIndex += adding;
      } else {
        // Not full
        break;
      }
    }
    return FilePartResult(position: newPosition, list: list);
  }

  int pageIndexFromPosition(int position) => position ~/ pageSize;

  // exclusive
  int endPageIndexFromPosition(int position) => pageCountFromSize(position);

  int pageCountFromSize(int size) =>
      pageCountFromSizeAndPageSize(size, pageSize);

  int getFilePartPosition(int partIndex, int inPartIndex) {
    return partIndex * pageSize + inPartIndex;
  }
}

/// Page count from size and page size.
int pageCountFromSizeAndPageSize(int size, int pageSize) =>
    size == 0 ? 0 : (pageSize == 0 ? 1 : ((((size - 1) ~/ pageSize)) + 1));

/// Paging reference
class FilePartRef {
  final int fileId;
  final int index;

  FilePartRef(this.fileId, this.index);

  List<int> toKey() => [fileId, index];

  factory FilePartRef.fromKey(Object key) {
    var parts = key as List;
    return FilePartRef(parts[0] as int, parts[1] as int);
  }

  @override
  int get hashCode => fileId + index;

  @override
  bool operator ==(Object other) {
    if (other is FilePartRef) {
      if (other.fileId != fileId) {
        return false;
      }
      if (other.index != index) {
        return false;
      }
      return true;
    }
    return false;
  }

  @override
  String toString() => toKey().toString();
}
