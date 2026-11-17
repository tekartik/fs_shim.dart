@TestOn('browser')
library;

import 'package:fs_shim/src/idb/idb_file_system.dart';
import 'package:tekartik_fs_browser/fs_browser.dart';
import 'package:tekartik_fs_test/fs_test.dart';
import 'package:tekartik_fs_test/test_common.dart';
import 'package:test/test.dart';

class FileSystemTestContextIdbBrowser extends IdbFileSystemTestContext {
  @override
  final IdbFileSystem rawFsIdb; // Needed for initialization (supportsLink)
  FileSystemTestContextIdbBrowser(FileSystem fs)
    : rawFsIdb = fs as IdbFileSystem {
    platform = platformContextBrowser;
  }
}

/// [fileSystemWeb], 256 KiB pages.
FileSystemTestContextIdbBrowser fileSystemTestContextIdbBrowser =
    FileSystemTestContextIdbBrowser(fileSystemWeb);

/// [fileSystemWebNoPaging], one record per file.
FileSystemTestContextIdbBrowser fileSystemTestContextIdbBrowserNoPaging =
    FileSystemTestContextIdbBrowser(fileSystemWebNoPaging);

void main() {
  group('browser', () {
    defineTests(fileSystemTestContextIdbBrowser);
  });
  group('browser_no_paging', () {
    defineTests(fileSystemTestContextIdbBrowserNoPaging);
  });
}
