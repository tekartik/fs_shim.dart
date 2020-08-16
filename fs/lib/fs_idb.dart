library fs_shim.fs_idb;

import 'package:fs_shim/src/idb/idb_fs.dart';
import 'package:idb_shim/idb.dart' as idb;

import 'fs.dart';

export 'fs.dart';

///
/// Idb implementation (base for memory and browser)
///
FileSystem newFileSystemIdb(idb.IdbFactory idbFactory, [String name]) =>
    IdbFileSystem(idbFactory, name);

/// Prefer newFileSystemIdb
@Deprecated('use newFileSystemIdb')
FileSystem newIdbFileSystem(idb.IdbFactory idbFactory, [String name]) =>
    newFileSystemIdb(idbFactory, name);
