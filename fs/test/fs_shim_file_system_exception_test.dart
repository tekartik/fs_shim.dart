// Copyright (c) 2015, <your name>. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library fs_shim.test.fs_shim_file_system_exception_test;

import 'package:fs_shim/fs.dart';
import 'test_common.dart';
import 'package:path/path.dart';

void main() {
  defineTests(memoryFileSystemTestContext);
}

FileSystemTestContext _ctx;
FileSystem get fs => _ctx.fs;

final bool _doPrintErr = false;
void _printErr(e) {
  if (_doPrintErr) {
    print("${e} ${[e.runtimeType]}");
  }
}

void defineTests(FileSystemTestContext ctx) {
  _ctx = ctx;

  group('file_system_exception_test', () {
    test('not_found', () async {
      Directory dir = await ctx.prepare();

      // create a file too deep
      Directory subDir = fs.newDirectory(join(dir.path, "sub"));
      File file = fs.newFile(join(subDir.path, "file"));

      try {
        await file.create();
        fail("shoud fail");
      } on FileSystemException catch (e) {
        _printErr(e);
        expect(e.osError.errorCode, isNotNull);
        expect(e.status, FileSystemException.statusNotFound);
        // FileSystemException: Creation failed, path = '/media/ssd/devx/hg/dart-pkg/lib/fs_shim/test_out/io/dir/create_recursive/sub/subsub' (OS Error: No such file or directory, errno = 2)
        // FileSystemException: Creation failed, path = '/default/dir/create_recursive/sub/subsub' (OS Error: No such file or directory, errno = 2)
      }
    });
  });
}
