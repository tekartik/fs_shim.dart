@TestOn('vm')
library;

import 'package:path/path.dart';
import 'package:tekartik_fs_test/fs_test.dart';
import 'package:test/test.dart';

import 'fs_io_test.dart';

void main() {
  group('io', () {
    defineTests(
      fileSystemTestContextIo.sandbox(
        path: join('.dart_tool', 'tekartik_fs_shim', 'test', 'io_sandbox'),
      ),
    );
  });
}
