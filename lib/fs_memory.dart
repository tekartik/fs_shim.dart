library tekartik_fs_shim.lfs_memory;

import 'package:tekartik_fs_shim/src/idb/fs_idb.dart';
import 'package:idb_shim/idb_client_memory.dart';

///
/// In memory implementation
///
class MemoryFileSystem extends IdbFileSystem {
  MemoryFileSystem([String name]) : super(idbMemoryFactory, name);
}
