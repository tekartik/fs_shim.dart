// Copyright (c) 2015, <your name>. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library;

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
    test('write above root', () async {
      var p = ctx.fs.path;
      var sep = p.separator;
      var path = p.join(sep, '..', 'test.txt');
      var absolutePath = ctx.fs.path.absolute(path);
      expect(absolutePath, path);
      var file = ctx.fs.file(absolutePath);
      if (fs is! FsShimSandboxedFileSystem) {
        expect(await file.exists(), isFalse);
      }
      try {
        await file.create(recursive: true);
      } on FileSystemException catch (e) {
        // error [5] PathAccessException: Cannot create file,
        // path = '/../test.txt' (OS Error: Permission denied, errno = 13)

        /// To adapt for CI maybe
        expect(e.status, FileSystemException.statusAccessError);
      }
      try {
        await file.parent.create(recursive: true);
      } on FileSystemException catch (e) {
        // error [5] PathAccessException: Cannot create file,
        // path = '/../test.txt' (OS Error: Permission denied, errno = 13)

        /// To adapt for CI maybe
        expect(e.status, FileSystemException.statusAccessError);
      }
    }, skip: 'Only valid for io for now, other fs allow it');

    test('sandbox', () async {
      final dir = await ctx.prepare();
      //debugDevPrintEnabled = true;
      var sandbox = ctx.fs.sandbox(path: dir.path) as FsShimSandboxedFileSystem;

      var filePath = 'myfile.txt';

      final file = fs.file(ctx.path.join(dir.path, filePath));
      await file.writeAsString('hello');
      var sandboxedFile = sandbox.file(filePath);
      final content = await sandboxedFile.readAsString();
      expect(content, 'hello');
    });
  });
}
