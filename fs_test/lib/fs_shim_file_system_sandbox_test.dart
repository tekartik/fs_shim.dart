// Copyright (c) 2015, <your name>. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library;

import 'package:dev_test/test.dart';
import 'package:path/path.dart' as path_prefix;

import 'test_common.dart';

void main() {
  defineFileSystemSandboxTests(memoryFileSystemTestContext);
}

void defineFileSystemSandboxTests(FileSystemTestContext ctx) {
  var fs = ctx.fs;
  var p = ctx.path;

  group('file_system_sandbox', () {
    test('delegatePath', () async {
      var sep = p.separator;
      var rootPath = p.join(fs.currentDirectory.path, 'root');
      var otherRootPath = '${sep}otherRoot';
      var sandbox = ctx.fs.sandbox(path: rootPath) as FsShimSandboxedFileSystem;

      var filePath = 'myfile.txt';

      var delegatePath = sandbox.delegatePath(filePath);

      expect(delegatePath, p.join(rootPath, filePath));

      /// Always returns absolute path
      expect(
        sandbox.sandboxPath(p.join(rootPath, filePath)),
        p.join(sep, filePath),
      );
      expect(
        () => sandbox.sandboxPath(p.join(otherRootPath, filePath)),
        throwsA(isA<path_prefix.PathException>()),
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

      //debugDevPrintEnabled = true;
      var sandbox = ctx.fs.sandbox(path: dir.path) as FsShimSandboxedFileSystem;

      expect(sandbox.currentDirectory.path, p.separator);
      expect(sandbox.rootDirectory, dir);
      expect(sandbox.rootDirectory.fs, dir.fs);
      var same = sandbox.sandbox() as FsShimSandboxedFileSystem;
      expect(same.currentDirectory.path, p.separator);
      expect(same.rootDirectory, sandbox.directory(p.separator));

      var rootDir = sandbox.recursiveUnsandbox();
      var rootDir2 = same.recursiveUnsandbox();
      if (fs is! FsShimSandboxedFileSystem) {
        expect(rootDir, dir);
        expect(rootDir2, dir);
      }

      var unsandboxed = sandbox.unsandbox();
      expect(unsandboxed, dir);

      expect(same, sandbox);
      same =
          sandbox.sandbox(path: sandbox.currentDirectory.path)
              as FsShimSandboxedFileSystem;

      expect(same, sandbox);
      expect(ctx.fs.sandbox(path: dir.path), sandbox);

      var filePath = 'myfile.txt';

      final file = fs.file(p.join(dir.path, filePath));
      await file.writeAsString('hello');
      var sandboxedFile = sandbox.file(filePath);
      var mainPath = p.join(dir.path, filePath);
      expect(sandbox.delegatePath(filePath), mainPath);
      final content = await sandboxedFile.readAsString();
      expect(sandbox.sandboxPath(mainPath), p.join(p.separator, filePath));
      expect(content, 'hello');

      expect(sandbox.unsandbox(), dir);

      if (ctx.fs is! FsShimSandboxedFileSystem) {
        expect(sandbox.recursiveUnsandbox(), dir);
        expect(sandbox.recursiveUnsandbox(path: 'test'), dir.directory('test'));
      }

      /// Handle if ctx.fs is already sandboxed
      expect(
        sandbox.recursiveUnsandbox(),
        ctx.fs.recursiveUnsandbox(path: dir.path),
      );
      expect(sandbox.unsandbox(path: 'test'), dir.directory('test'));
      expect(
        sandbox.recursiveUnsandbox(path: 'test'),
        ctx.fs.recursiveUnsandbox(path: dir.directory('test').path),
      );
    });
    test('two levels sandbox', () async {
      final dir = await ctx.prepare();
      var p = ctx.path;
      var sep = p.separator;
      //debugDevPrintEnabled = true;
      var sandbox = ctx.fs.sandbox(path: dir.path) as FsShimSandboxedFileSystem;
      var sandbox2Path = p.join('sub1', 'sub2');
      var sandbox2 =
          sandbox.sandbox(path: sandbox2Path) as FsShimSandboxedFileSystem;
      expect(sandbox2, isNot(sandbox));
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

      expect(sandbox.unsandbox(), dir);
      expect(sandbox2.unsandbox(), sandbox2.rootDirectory);
      expect(
        sandbox2.unsandbox(path: 'test'),
        sandbox2.rootDirectory.directory('test'),
      );
      if (ctx.fs is! FsShimSandboxedFileSystem) {
        expect(sandbox.recursiveUnsandbox(), dir);
        expect(sandbox2.recursiveUnsandbox(), dir.directory(sandbox2Path));
        expect(
          sandbox2.recursiveUnsandbox(path: 'test'),
          dir.directory(p.join(sandbox2Path, 'test')),
        );
      }
    });
  });
}
