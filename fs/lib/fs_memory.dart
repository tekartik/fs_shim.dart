library fs_shim.fs_memory;

import 'package:idb_shim/idb_client_memory.dart';

import 'fs.dart';
import 'fs_idb.dart';

export 'fs.dart';

///
/// In memory implementation
///
@Deprecated('Use newFileSystemMemory instead')
FileSystem newMemoryFileSystem([String name]) => newFileSystemMemory(name);

/// Creates a new file system in memory.
FileSystem newFileSystemMemory([String name]) =>
    newFileSystemIdb(newIdbFactoryMemory(), name);

FileSystem _fileSystemMemory;

/// Global in memory file system.
FileSystem get fileSystemMemory => _fileSystemMemory ??= newFileSystemMemory();
