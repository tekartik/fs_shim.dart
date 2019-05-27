@TestOn('browser')
import 'package:dev_test/test.dart';
import 'package:fs_shim/src/idb/idb_file_system.dart';
import 'package:tekartik_fs_browser/fs_browser.dart';
import 'package:tekartik_fs_test/fs_test.dart';
import 'package:tekartik_fs_test/test_common.dart';
import 'package:tekartik_platform/context.dart';
import 'package:tekartik_platform_browser/context_browser.dart';

class FileSystemTestContextIdbBrowser extends IdbFileSystemTestContext {
  @override
  final PlatformContext platform = platformContextBrowser;
  @override
  IdbFileSystem fs = fileSystemIdb
      as IdbFileSystem; // Needed for initialization (supportsLink)
  FileSystemTestContextIdbBrowser();
}

FileSystemTestContextIdbBrowser fileSystemTestContextIdbBrowser =
    FileSystemTestContextIdbBrowser();

void main() {
  group('browser', () {
    defineTests(fileSystemTestContextIdbBrowser);
  });
}
