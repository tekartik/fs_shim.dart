library fs_shim.fs_memory;

import 'package:idb_shim/idb_client_sembast.dart';
import 'package:sembast/sembast_memory.dart';

import 'fs_idb.dart';

export 'fs.dart';

///
/// In memory implementation
///
@Deprecated('Use newFileSystemMemory instead')
FileSystem newMemoryFileSystem([String? name]) => newFileSystemMemory(name);

/// Creates a new file system in memory.
FileSystem newFileSystemMemory([String? name]) => newFileSystemIdb(
    //newFileSystemIdb(idbFactory)
    //newIdbFactoryMemory(),
    IdbFactorySembast(newDatabaseFactoryMemory()),
    // Logger in warning
    name);

FileSystem? _fileSystemMemory;

/// Global in memory file system.
FileSystem get fileSystemMemory => _fileSystemMemory ??= newFileSystemMemory();
