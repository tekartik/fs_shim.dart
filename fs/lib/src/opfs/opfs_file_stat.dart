// ignore_for_file: public_member_api_docs

import 'package:fs_shim/fs.dart' as fs;
import 'package:fs_shim/src/common/fs_mixin.dart';

final _epochDateTime = DateTime.fromMillisecondsSinceEpoch(0).toUtc();

/// OpfsFileStat representation.
class OpfsFileStat with FileStatModeMixin implements fs.FileStat {
  int? _size;

  @override
  int get size => _size ?? -1;

  set size(int size) => _size = size;

  @override
  fs.FileSystemEntityType? type;

  DateTime? _modified;

  set modified(DateTime modified) => _modified = modified;

  @override
  DateTime get modified => _modified ?? _epochDateTime;

  @override
  String toString() {
    final map = <String, Object?>{'type': type};
    if (_modified != null) {
      map['modified'] = _modified;
    }
    if (_size != null) {
      map['size'] = size;
    }
    return map.toString();
  }
}
