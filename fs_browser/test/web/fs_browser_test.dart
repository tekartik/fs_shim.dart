@TestOn('browser')
library;

import 'package:fs_shim/src/idb/idb_file_system.dart';
import 'package:tekartik_fs_browser/fs_browser.dart';
import 'package:tekartik_fs_test/fs_test.dart';
import 'package:tekartik_fs_test/test_common.dart';
import 'package:test/test.dart';

class FileSystemTestContextIdbBrowser extends IdbFileSystemTestContext {
  @override
  IdbFileSystem rawFsIdb = fileSystemIdb as IdbFileSystem; // Needed for initialization (supportsLink)
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
