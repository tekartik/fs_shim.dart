// Copyright (c) 2015, <your name>. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library fs_shim.fs_test;

import 'test_common.dart';
import 'fs_shim_dir_test.dart' as dir_test;
import 'fs_shim_file_test.dart' as file_test;
import 'fs_shim_link_test.dart' as link_test;

main() {
  group('default', () {
    defineTests(memoryFileSystemTestContext);
  });
}

void defineTests(FileSystemTestContext ctx) {
  dir_test.defineTests(ctx);
  file_test.defineTests(ctx);
  link_test.defineTests(ctx);
}
