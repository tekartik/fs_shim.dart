// Copyright (c) 2015, <your name>. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library;

import 'package:dev_test/test.dart';

import 'fs_shim_dir_test.dart' as dir_test;
import 'fs_shim_file_stat_test.dart' as file_stat_test;
import 'fs_shim_file_system_exception_test.dart' as file_system_exception_test;
import 'fs_shim_file_system_test.dart' as file_system_test;
import 'fs_shim_file_test.dart' as file_test;
import 'fs_shim_link_test.dart' as link_test;
import 'fs_shim_random_access_file_test.dart' as random_access_file_test;
import 'fs_shim_sanity_test.dart' as fs_shim_sanity_test;
import 'test_common.dart';
import 'utils_test.dart' as utils_test;

void main() {
  group('default', () {
    defineFsTests(memoryFileSystemTestContext);
  });
}

// To deprecate
void defineTests(FileSystemTestContext ctx) {
  defineFsTests(ctx);
}

void defineFsTests(FileSystemTestContext ctx) {
  dir_test.defineTests(ctx);
  file_test.defineTests(ctx);
  link_test.defineTests(ctx);
  file_stat_test.defineTests(ctx);
  file_system_test.defineTests(ctx);
  file_system_exception_test.defineTests(ctx);
  fs_shim_sanity_test.defineTests(ctx);
  random_access_file_test.defineTests(ctx);
  utils_test.defineTests(ctx);
}
