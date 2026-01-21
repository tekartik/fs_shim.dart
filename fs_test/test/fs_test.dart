// Copyright (c) 2015, <your name>. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library;

import 'package:dev_test/test.dart';
import 'package:fs_shim/fs_memory.dart';
import 'package:tekartik_fs_test/fs_test.dart';

void main() {
  group('default', () {
    defineFsTests(memoryFileSystemTestContext);
    group('empty', () {
      late FileSystem fs;
      setUp(() {
        fs = newFileSystemMemory();
      });
      tearDown(() {});
      test('root', () async {
        expect(await fs.currentDirectory.exists(), isFalse);
      });
    });
  });
}
