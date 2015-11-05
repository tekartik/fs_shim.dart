library tekartik_fs_shim.lfs_browser;

import 'package:tekartik_fs_shim/src/idb/fs_idb.dart';
import 'package:idb_shim/idb_browser.dart';

class BrowserFileSystem extends IdbFileSystem {
  ///
  /// Over browser db implementation
  ///
  BrowserFileSystem([String name]) : super(idbBrowserFactory, name);
}
