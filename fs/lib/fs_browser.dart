import 'package:fs_shim/fs_idb.dart';
import 'package:fs_shim/src/web/fs_web.dart';

/// The default browser file system on top of IndexedDB.
FileSystem get fileSystemIdb => fileSystemWeb;
