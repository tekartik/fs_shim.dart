// Copyright (c) 2015, <your name>. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library;

import 'package:dev_test/test.dart';
// ignore_for_file: unnecessary_import
import 'package:fs_shim/fs.dart';

import 'test_common.dart';

void main() {
  defineTests(memoryFileSystemTestContext);
}

final bool _doPrintErr = false;

void _printErr(Object? e) {
  if (_doPrintErr) {
    // ignore: avoid_print
    print('$e ${[e.runtimeType]}');
  }
}

void defineTests(FileSystemTestContext ctx) {
  var fs = ctx.fs;

  group('file_system_exception_test', () {
    test('not_found', () async {
      final dir = await ctx.prepare();

      // create a file too deep
      final subDir = fs.directory(fs.path.join(dir.path, 'sub'));
      final file = fs.file(fs.path.join(subDir.path, 'file'));

      try {
        await file.create();
        fail('shoud fail');
      } on FileSystemException catch (e) {
        _printErr(e);
        if (e.osError != null) {
          expect(e.osError!.errorCode, isNotNull);
        }
        expect(e.status, FileSystemException.statusNotFound);
        // FileSystemException: Creation failed, path = '/media/ssd/devx/hg/dart-pkg/lib/fs_shim/test_out/io/dir/create_recursive/sub/subsub' (OS Error: No such file or directory, errno = 2)
        // FileSystemException: Creation failed, path = '/default/dir/create_recursive/sub/subsub' (OS Error: No such file or directory, errno = 2)
      }
    });
  });
}
