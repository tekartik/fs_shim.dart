library fs_shim.src.idb.idb_file_stat;

import '../../fs.dart' as fs;

class IdbFileStat implements fs.FileStat {
  int _size;
  int get size => _size == null ? -1 : _size;
  set size(int size) => _size = size;
  fs.FileSystemEntityType type;
  DateTime modified;

  String toString() {
    Map map = {"type": type};
    if (modified != null) {
      map["modified"] = modified;
    }
    if (_size != null) {
      map["size"] = size;
    }
    return map.toString();
  }
}
