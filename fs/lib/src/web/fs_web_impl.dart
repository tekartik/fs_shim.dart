import 'package:fs_shim/fs_idb.dart';
import 'package:idb_shim/idb_client_native.dart';

/// The default browser file system on top of IndexedDB.
final FileSystem fileSystemWeb = newFileSystemIdb(idbFactoryNative);
