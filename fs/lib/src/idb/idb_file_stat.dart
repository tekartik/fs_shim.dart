import 'package:fs_shim/fs.dart' as fs;

class IdbFileStat implements fs.FileStat {
  int _size;

  @override
  int get size => _size == null ? -1 : _size;

  set size(int size) => _size = size;

  @override
  fs.FileSystemEntityType type;

  @override
  DateTime modified;

  @override
  String toString() {
    final map = <String, dynamic>{'type': type};
    if (modified != null) {
      map['modified'] = modified;
    }
    if (_size != null) {
      map['size'] = size;
    }
    return map.toString();
  }
}
