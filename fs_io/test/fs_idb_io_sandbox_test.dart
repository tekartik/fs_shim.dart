@TestOn('vm')
// Copyright (c) 2015, Alexandre Roux. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.
library;

import 'package:tekartik_fs_test/fs_test.dart';
import 'package:test/test.dart';

import 'fs_idb_io_test.dart';

void main() {
  // debugIdbShowLogs = devWarning(true);
  group('idb_io_sandbox', () {
    group('fs_tests', () {
      defineFsTests(FileSystemTestContextIdbIo().sandbox(path: '/root'));
    });
  });
}
