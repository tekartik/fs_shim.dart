// Copyright (c) 2015, <your name>. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library fs_shim.test.fs_shim_file_system_test;

import 'package:dev_test/test.dart';

import 'test_common.dart';

void main() {
  defineTests(memoryFileSystemTestContext);
}

void defineTests(FileSystemTestContext ctx) {
  var fs = ctx.fs;

  group('file_system', () {
    test('equals', () {
      expect(fs, fs);
    });

    test('pathContext', () {
      // for now all are the same as current
      // expect(fs.path, context);
    });

    test('prepare', () async {
      final top = await ctx.prepare();

      // no check
      ctx.fs.path.split(top.path);
    });
  });
}
