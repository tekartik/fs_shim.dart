@TestOn('browser')
library;

import 'package:tekartik_fs_test/fs_test.dart';
import 'package:test/test.dart';

import 'fs_browser_test.dart';

void main() {
  group('browser_sandbox', () {
    defineTests(fileSystemTestContextIdbBrowser.sandbox(path: '/root'));
  });
}
