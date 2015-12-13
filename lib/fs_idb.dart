library fs_shim.fs_idb;

import 'package:fs_shim/src/idb/idb_fs.dart' as idb_fs;
import 'package:idb_shim/idb.dart' as idb;

///
/// Idb implementation (base for memory and browser)
///
class IdbFileSystem extends idb_fs.IdbFileSystem {
  IdbFileSystem(idb.IdbFactory idbFactory, [String name])
      : super(idbFactory, name);
}
