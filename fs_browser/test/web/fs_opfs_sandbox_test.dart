@TestOn('browser')
library;

import 'package:tekartik_fs_test/fs_test.dart';
import 'package:test/test.dart';

import 'fs_opfs_test.dart';

void main() {
  group('opfs_sandbox', () {
    defineTests(fileSystemTestContextOpfs.sandbox(path: '/root'));
  });
}
