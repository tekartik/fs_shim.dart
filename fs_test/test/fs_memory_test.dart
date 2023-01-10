// Copyright (c) 2015, <your name>. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library tekartik_fs_test.fs_memory_test;

import 'package:fs_shim/fs_idb.dart';
import 'package:fs_shim/fs_memory.dart';
import 'package:tekartik_fs_test/fs_current_dir_file_test.dart' as current_dir;
import 'package:tekartik_fs_test/fs_test.dart';
import 'package:tekartik_fs_test/test_common.dart';

void defineAllIdbTests(IdbFileSystemTestContext ctx) {
  group('options: ${ctx.fs.idbOptions} ', () {
    current_dir.defineTests(ctx.fs);
    defineTests(memoryFileSystemTestContext);
  });
}

void main() {
  group('memory', () {
    group('pageSize: null twice', () {
      defineAllIdbTests(MemoryFileSystemTestContext());

      defineAllIdbTests(MemoryFileSystemTestContextWithOptions(
          options: const FileSystemIdbOptions(pageSize: 16 * 1024)));
      defineAllIdbTests(MemoryFileSystemTestContextWithOptions(
          options: const FileSystemIdbOptions(pageSize: 2)));
      defineAllIdbTests(MemoryFileSystemTestContextWithOptions(
          options: const FileSystemIdbOptions(pageSize: 4)));
      defineAllIdbTests(MemoryFileSystemTestContextWithOptions(
          options: const FileSystemIdbOptions(pageSize: 1024)));
    });

    // Copied from source test
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
