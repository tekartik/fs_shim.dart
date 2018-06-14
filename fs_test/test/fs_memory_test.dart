// Copyright (c) 2015, <your name>. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library tekartik_fs_test.fs_memory_test;

import 'package:dev_test/test.dart';
import 'package:tekartik_fs_test/fs_test.dart';
import 'package:tekartik_fs_test/test_common.dart';

main() {
  group('default', () {
    defineTests(memoryFileSystemTestContext);
  });
}
