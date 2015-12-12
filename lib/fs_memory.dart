library fs_shim.lfs_memory;

import 'package:fs_shim/src/idb/idb_fs.dart';
import 'package:idb_shim/idb_client_memory.dart';

///
/// In memory implementation
///
class MemoryFileSystem extends IdbFileSystem {
  MemoryFileSystem([String name]) : super(idbMemoryFactory, name);
}
