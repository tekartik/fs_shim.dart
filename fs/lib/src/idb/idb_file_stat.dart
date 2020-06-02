import 'package:fs_shim/fs.dart' as fs;

final _epochDateTime = DateTime.fromMillisecondsSinceEpoch(0).toUtc();

class IdbFileStat implements fs.FileStat {
  int _size;

  @override
  int get size => _size ?? -1;

  set size(int size) => _size = size;

  @override
  fs.FileSystemEntityType type;

  DateTime _modified;

  set modified(DateTime modified) => _modified = modified;

  // No long null since 2.8.0
  @override
  DateTime get modified => _modified ?? _epochDateTime;

  @override
  String toString() {
    final map = <String, dynamic>{'type': type};
    if (_modified != null) {
      map['modified'] = _modified;
    }
    if (_size != null) {
      map['size'] = size;
    }
    return map.toString();
  }
}
