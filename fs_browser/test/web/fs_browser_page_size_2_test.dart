@TestOn('browser')
library;

import 'package:fs_shim/fs_idb.dart';
import 'package:tekartik_fs_test/fs_test.dart';
import 'package:tekartik_fs_test/fs_test_web.dart';
import 'package:test/test.dart';

void main() {
  group('browser_page_size_2', () {
    defineTests(FileSystemTestContextIdbWeb(
        options: const FileSystemIdbOptions(pageSize: 2)));
  });
}
