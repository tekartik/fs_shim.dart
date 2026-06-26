@TestOn('browser')
library;

import 'package:fs_shim/fs_opfs_web.dart';
import 'package:tekartik_fs_test/fs_test.dart';
import 'package:tekartik_fs_test/test_common.dart';
import 'package:test/test.dart';

/// Test context for the OPFS (Origin Private File System) file system.
class FileSystemTestContextOpfs with FileSystemTestContextMixin {
  @override
  final FileSystem fs = fileSystemOpfsWeb;

  FileSystemTestContextOpfs() {
    platform = platformContextBrowser;
  }

  @override
  PlatformContext? platform;

  @override
  String toString() => 'OpfsFsTestContext($fs)';
}

final fileSystemTestContextOpfs = FileSystemTestContextOpfs();

void main() {
  group('opfs', () {
    test('name', () {
      expect(fileSystemTestContextOpfs.fs.name, 'opfs');
      expect(fileSystemTestContextOpfs.fs.supportsLink, isFalse);
      expect(fileSystemTestContextOpfs.fs.supportsRandomAccess, isFalse);
    });
    defineTests(fileSystemTestContextOpfs);
  });
}
