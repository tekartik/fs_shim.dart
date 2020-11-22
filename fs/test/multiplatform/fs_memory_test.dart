// Copyright (c) 2015, <your name>. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library tekartik_fs_test.fs_memory_test;

import 'package:test/test.dart';
import 'package:fs_shim/fs_memory.dart';

import 'fs_test.dart';
import 'test_common.dart';

void main() {
  group('memory', () {
    defineTests(memoryFileSystemTestContext);

    group('top', () {
      test('writeAsString', () async {
        // direct file write, no preparation
        var fs = newFileSystemMemory();
        await fs.file('file.tmp').writeAsString('context');
      }, skip: false);

      test('createDirectory', () async {
        // direct file write, no preparation
        var fs = newFileSystemMemory();
        await fs.directory('dir.tmp').create();
      }, skip: false);

      test('createDirectoryRecursive', () async {
        // direct file write, no preparation
        var fs = newFileSystemMemory();
        var path = fs.path;
        await fs.directory(path.join('dir.tmp', 'sub')).create(recursive: true);
      }, skip: false);
    });
  });
}
