library fs_shim.fs_memory;

import 'package:idb_shim/idb_client_memory.dart';
import 'fs_idb.dart';

///
/// In memory implementation
///
class MemoryFileSystem extends IdbFileSystem {
  MemoryFileSystem([String name]) : super(idbMemoryFactory, name);
}
