// Copyright (c) 2015, <your name>. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library fs_shim.fs_test;

import 'test_common.dart';
import 'fs_shim_dir_test.dart' as dir_test;
import 'fs_shim_file_test.dart' as file_test;
import 'fs_shim_link_test.dart' as link_test;
import 'fs_shim_file_stat_test.dart' as file_stat_test;
import 'fs_shim_file_system_test.dart' as file_system_test;
import 'fs_shim_file_system_exception_test.dart' as file_system_exception_test;

import 'utils_copy_test.dart' as utils_copy_test;
import 'utils_entity_test.dart' as utils_entity_test;
import 'utils_part_test.dart' as utils_part_test;
import 'utils_path_test.dart' as utils_path_test;
import 'utils_read_write_test.dart' as utils_read_write_test;

import 'fs_shim_sanity_test.dart' as fs_shim_sanity_test;

main() {
  group('default', () {
    defineTests(memoryFileSystemTestContext);
  });
}

void defineTests(FileSystemTestContext ctx) {
  dir_test.defineTests(ctx);
  file_test.defineTests(ctx);
  link_test.defineTests(ctx);
  file_stat_test.defineTests(ctx);
  file_system_test.defineTests(ctx);
  file_system_exception_test.defineTests(ctx);

  fs_shim_sanity_test.defineTests(ctx);

  utils_copy_test.defineTests(ctx);
  utils_entity_test.defineTests(ctx);
  // no: utils_glob_test.defineTests(ctx);
  utils_part_test.defineTests(ctx);
  utils_path_test.defineTests(ctx);
  utils_read_write_test.defineTests(ctx);
}
