library fs_shim.fs_idb;

import 'package:idb_shim/idb.dart' as idb;
import 'package:fs_shim/src/idb/idb_fs.dart';
import 'fs.dart';

///
/// Idb implementation (base for memory and browser)
///
FileSystem newIdbFileSystem(idb.IdbFactory idbFactory, [String name]) =>
    new IdbFileSystem(idbFactory, name);
