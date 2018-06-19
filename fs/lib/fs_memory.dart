library fs_shim.fs_memory;

import 'package:idb_shim/idb_client_memory.dart';

import 'fs.dart';
import 'fs_idb.dart';

export 'fs.dart';

///
/// In memory implementation
///
// @Deprecated("Use newFileSystemMemory instead")
FileSystem newMemoryFileSystem([String name]) => newFileSystemMemory(name);

FileSystem newFileSystemMemory([String name]) =>
    newIdbFileSystem(idbMemoryFactory, name);
