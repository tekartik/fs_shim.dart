// Copyright (c) 2015, <your name>. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library;

import 'package:dev_test/test.dart';
import 'package:fs_shim/fs_memory.dart';
import 'package:tekartik_fs_test/fs_test.dart';

void main() {
  group('sandbox', () {
    defineFsTests(memoryFileSystemTestContext.sandbox(path: '/root'));
    defineFsTests(memoryFileSystemTestContext.sandbox(path: 'relative_root'));
    defineFsTests(
      memoryFileSystemTestContext
          .sandbox(path: 'sub_route1/sub_route2/')
          .sandbox(path: '/sub_route3/sub_route4/'),
    );
    defineFsTests(
      memoryFileSystemTestContext
          .sandbox(path: 'sub_route1/sub_route2/')
          .sandbox(path: '/sub_route3/sub_route4/')
          .sandbox(path: '/sub_route5/sub_route6'),
    );
    test('nested', () {
      var fs = newFileSystemMemory();
      var fs1 = fs.sandbox(path: '/sub1') as FsShimSandboxedFileSystem;
      var fs2 = fs1.sandbox(path: '/sub2') as FsShimSandboxedFileSystem;
      expect(fs2.rootDirectory.path, '/sub1/sub2');
      expect(fs2.rootDirectory.fs, fs);
    });
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
