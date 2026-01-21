// Copyright (c) 2015, <your name>. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library;

import 'package:dev_test/test.dart';
import 'package:path/path.dart';
import 'test_common.dart';

void main() {
  defineFileSystemSandboxTests(memoryFileSystemTestContext);
}

void defineFileSystemSandboxTests(FileSystemTestContext ctx) {
  var fs = ctx.fs;

  group('file_system_sandbox', () {
    test('delegatePath', () async {
      var p = ctx.path;
      var sep = p.separator;
      var rootPath = '${sep}root';
      var otherRootPath = '${sep}otherRoot';
      var sandbox = ctx.fs.sandbox(path: rootPath) as FsShimSandboxedFileSystem;

      var filePath = 'myfile.txt';

      expect(sandbox.delegatePath(filePath), p.join(rootPath, filePath));

      /// Always returns absolute path
      expect(
        sandbox.sandboxPath(p.join(rootPath, filePath)),
        p.join(sep, filePath),
      );
      expect(
        () => sandbox.sandboxPath(p.join(otherRootPath, filePath)),
        throwsA(isA<PathException>()),
      );

      var sandbox2 =
          sandbox.sandbox(path: '/subdir') as FsShimSandboxedFileSystem;
      var delegate2Path = sandbox2.delegatePath(filePath);
      expect(delegate2Path, p.join(sep, 'subdir', filePath));
      var delegate1Path = sandbox.delegatePath(delegate2Path);
      expect(delegate1Path, p.join(rootPath, 'subdir', filePath));
    });

    test('single level sandbox', () async {
      final dir = await ctx.prepare();
      var p = ctx.path;
      //debugDevPrintEnabled = true;
      var sandbox = ctx.fs.sandbox(path: dir.path) as FsShimSandboxedFileSystem;

      var filePath = 'myfile.txt';

      final file = fs.file(p.join(dir.path, filePath));
      await file.writeAsString('hello');
      var sandboxedFile = sandbox.file(filePath);
      var mainPath = p.join(dir.path, filePath);
      expect(sandbox.delegatePath(filePath), mainPath);
      final content = await sandboxedFile.readAsString();
      expect(sandbox.sandboxPath(mainPath), join(p.separator, filePath));
      expect(content, 'hello');
    });
    test('two levels sandbox', () async {
      final dir = await ctx.prepare();
      var p = ctx.path;
      var sep = p.separator;
      //debugDevPrintEnabled = true;
      var sandbox = ctx.fs.sandbox(path: dir.path) as FsShimSandboxedFileSystem;
      var sandbox2 =
          sandbox.sandbox(path: p.join(p.separator, 'sub1', 'sub2'))
              as FsShimSandboxedFileSystem;

      var filePath = 'myfile.txt';
      var sandboxed2File = sandbox2.file(filePath);
      var delegate2Path = sandbox2.delegatePath(filePath);
      expect(delegate2Path, p.join(sep, 'sub1', 'sub2', filePath));
      var delegate1Path = sandbox.delegatePath(delegate2Path);
      expect(delegate1Path, p.join(dir.path, 'sub1', 'sub2', filePath));

      await sandboxed2File.create(recursive: true);
      await sandboxed2File.writeAsString('hello');
      var sandboxed1File = sandbox.file(delegate2Path);
      //expect(sandbox.delegatePath(filePath), p.join(dir.path, filePath));
      final content = await sandboxed1File.readAsString();
      expect(content, 'hello');
    });
  });
}
