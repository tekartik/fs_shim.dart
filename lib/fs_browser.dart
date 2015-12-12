library fs_shim.lfs_browser;

import 'package:fs_shim/src/idb/idb_fs.dart';
import 'package:idb_shim/idb_browser.dart';

class BrowserFileSystem extends IdbFileSystem {
  ///
  /// Over browser db implementation
  ///
  BrowserFileSystem([String name]) : super(idbBrowserFactory, name);
}
