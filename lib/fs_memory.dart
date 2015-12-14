library fs_shim.fs_memory;

import 'package:idb_shim/idb_client_memory.dart';
import 'fs_idb.dart';
import 'fs.dart';

///
/// In memory implementation
///
FileSystem newMemoryFileSystem([String name]) =>
    newIdbFileSystem(idbMemoryFactory, name);
