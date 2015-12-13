library fs_shim.fs_browser;

import 'fs_idb.dart';
import 'package:idb_shim/idb_browser.dart';

class BrowserFileSystem extends IdbFileSystem {
  ///
  /// Over browser db implementation
  ///
  BrowserFileSystem([String name]) : super(idbBrowserFactory, name);
}
