@TestOn('vm')
library tekartik_fs_test.fs_io_test;

import 'package:fs_shim/fs_io.dart';
import 'package:tekartik_fs_test/fs_current_dir_file_test.dart' as current_dir;
import 'package:tekartik_fs_test/fs_test.dart';

import 'test_common_io.dart';

void main() {
  group('io', () {
    current_dir.defineTests(fileSystemIo);
    defineTests(fileSystemTestContextIo);
  });
}
