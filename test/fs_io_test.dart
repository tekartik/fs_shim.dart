@TestOn("vm")
// Copyright (c) 2015, Alexandre Roux. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library tekartik_fs_shim.fs_io_test;

import 'package:tekartik_fs_shim/fs.dart';
import 'package:dev_test/test.dart';
import 'fs_test.dart';
import 'test_common_io.dart';
import 'package:path/path.dart';

void main() {
  group('io', () {
    test('type', () async {
      expect(await ioFileSystemContext.fs.type(testScriptPath),
          FileSystemEntityType.FILE);
      expect(await ioFileSystemContext.fs.type(dirname(testScriptPath)),
          FileSystemEntityType.DIRECTORY);
    });
    test('test_path', () async {
      expect(ioFileSystemContext.outTopPath,
          join(dirname(dirname(testScriptPath)), "test_out"));
      expect(ioFileSystemContext.outPath,
          join(ioFileSystemContext.outTopPath, joinAll(testDescriptions)));
    });

    // All tests
    defineTests(ioFileSystemContext);
  });
}
