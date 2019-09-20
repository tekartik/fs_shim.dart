import 'package:fs_shim/fs_idb.dart';
// ignore: implementation_imports
import 'package:fs_shim/src/idb/idb_file_system.dart';

import 'package:idb_shim/idb_browser.dart';

IdbFileSystem fileSystemIdb =
    newFileSystemIdb(idbFactoryNative) as IdbFileSystem;
