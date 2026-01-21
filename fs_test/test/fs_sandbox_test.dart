// Copyright (c) 2015, <your name>. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library;

import 'package:dev_test/test.dart';
import 'package:fs_shim/fs_memory.dart';
import 'package:tekartik_fs_test/fs_test.dart';
import 'package:tekartik_fs_test/fs_test_common.dart';

void main() {
  group('sandbox', () {
    defineFsTests(memoryFileSystemTestContext.sandbox(path: '/root'));
    group('empty', () {
      late FsShimSandboxedFileSystem fs;
      setUp(() {
        fs =
            newFileSystemMemory().sandbox(path: '/sub/root')
                as FsShimSandboxedFileSystem;
      });
      tearDown(() {});
      test('root', () async {
        expect(await fs.currentDirectory.exists(), isFalse);
      });
      test('above root', () async {
        var file = fs.file('/../test.txt');
        var delegatePath = fs.delegatePath(file.path);
        // We never go above root
        expect(delegatePath, '/sub/root/test.txt');
      });
      test('relative to dot', () async {
        var file = fs.file('./test.txt');
        var delegatePath = fs.delegatePath(file.path);
        // We never go above root
        expect(delegatePath, '/sub/root/test.txt');
      });
    });
  });
}
