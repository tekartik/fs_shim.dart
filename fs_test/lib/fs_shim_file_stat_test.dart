// Copyright (c) 2015, <your name>. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library fs_shim.test.fs_shim_file_stat_test;

import 'package:fs_shim/fs.dart';
import 'package:path/path.dart';

import 'test_common.dart';

void main() {
  defineTests(memoryFileSystemTestContext);
}

FileSystemTestContext _ctx;

FileSystem get fs => _ctx.fs;

void defineTests(FileSystemTestContext ctx) {
  _ctx = ctx;

  group('file_stat', () {
    test('stat', () async {
      Directory top = await ctx.prepare();

      File file = fs.file(join(top.path, "file"));

      await file.writeAsString("test", flush: true);
      FileStat stat = await file.stat();
      expect(stat.type, FileSystemEntityType.file);
      expect(stat.size, 4);
      expect(stat.modified, isNotNull);
    });
  });
}
