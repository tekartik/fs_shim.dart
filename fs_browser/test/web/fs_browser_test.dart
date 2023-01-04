@TestOn('browser')
library fs_shim_browser.fs_browser_test;

import 'package:fs_shim/src/idb/idb_file_system.dart';
import 'package:tekartik_fs_browser/fs_browser.dart';
import 'package:tekartik_fs_test/fs_test.dart';
import 'package:tekartik_fs_test/test_common.dart';

class FileSystemTestContextIdbBrowser extends IdbFileSystemTestContext {
  @override
  IdbFileSystem fs = fileSystemIdb
      as IdbFileSystem; // Needed for initialization (supportsLink)
  FileSystemTestContextIdbBrowser() {
    platform = platformContextBrowser;
  }
}

FileSystemTestContextIdbBrowser fileSystemTestContextIdbBrowser =
    FileSystemTestContextIdbBrowser();

void main() {
  group('browser', () {
    defineTests(fileSystemTestContextIdbBrowser);
  });
}
