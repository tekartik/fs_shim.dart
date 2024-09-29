// Copyright (c) 2015, <your name>. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library;

import 'package:dev_test/test.dart';

import 'test_common.dart';
import 'utils_copy_test.dart' as utils_copy_test;
import 'utils_entity_test.dart' as utils_entity_test;
import 'utils_path_test.dart' as utils_path_test;
import 'utils_read_write_test.dart' as utils_read_write_test;

void main() {
  group('manual', () {
    defineTests(memoryFileSystemTestContext);
  });
}

void defineTests(FileSystemTestContext ctx) {
  group('utils', () {
    utils_copy_test.defineTests(ctx);
    utils_entity_test.defineTests(ctx);
    // no: utils_glob_test.defineTests(ctx);
    utils_path_test.defineTests(ctx);
    utils_read_write_test.defineTests(ctx);
  });
}
