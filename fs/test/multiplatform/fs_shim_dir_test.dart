// Copyright (c) 2015, <your name>. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library fs_shim.test.fs_shimdirectory_test;

// ignore_for_file: unnecessary_import
import 'package:fs_shim/fs.dart';

import 'fs_shim_file_stat_test.dart';
import 'test_common.dart';

void main() {
  defineTests(memoryFileSystemTestContext);
}

late FileSystemTestContext _ctx;

FileSystem get fs => _ctx.fs;

void defineTests(FileSystemTestContext ctx) {
  _ctx = ctx;

  group('dir', () {
    test('new', () {
      var dir = fs.directory('dummy');
      expect(dir.path, 'dummy');
      dir = fs.directory(r'\root/dummy');
      expect(dir.path, r'\root/dummy');
      dir = fs.directory(r'\');
      expect(dir.path, r'\');
      dir = fs.directory(r'');
      expect(dir.path, r'');
    });

    test('toString', () {
      final dir = fs.directory('dir');
      expect(dir.toString(), "Directory: '${dir.path}'");
    });

    test('absolute', () {
      var dir = fs.directory('dummy');
      expect(dir.isAbsolute, isFalse);

      dir = dir.absolute;
      expect(dir.isAbsolute, isTrue);
      expect(dir.absolute.path, dir.path);
    });

    test('prepare', () async {
      await ctx.prepare();
      await ctx.prepare();
    });

    test('exists', () async {
      final dir = await ctx.prepare();
      expect(await dir.exists(), isTrue);
      final subDir = fs.directory(fs.path.join(dir.path, 'sub'));
      expect(await subDir.exists(), isFalse);
    });

    test('create', () async {
      final dir = await ctx.prepare();

      final subDir = fs.directory(fs.path.join(dir.path, 'sub'));
      expect(await subDir.exists(), isFalse);
      expect(await fs.isDirectory(subDir.path), isFalse);
      expect(await (await subDir.create()).exists(), isTrue);
      expect(await fs.isDirectory(subDir.path), isTrue);

      // second time fine too
      await subDir.create();
    });

    test('stat', () async {
      final directory = await ctx.prepare();

      final dir = fs.directory(fs.path.join(directory.path, 'dir'));
      var stat = await dir.stat();
      expect(stat.type, FileSystemEntityType.notFound);
      expect(stat.size, -1);
      expectNotFoundDateTime(stat.modified);

      await dir.create();
      stat = await dir.stat();
      //print(stat);
      expect(stat.type, FileSystemEntityType.directory);
      expect(stat.size, isNot(-1));
      expect(stat.size, isNotNull);
      expect(stat.modified, isNotNull);
    });

    test('create_recursive', () async {
      final dir = await ctx.prepare();

      final subDir = fs.directory(fs.path.join(dir.path, 'sub'));
      final subSubDir = fs.directory(fs.path.join(subDir.path, 'subsub'));

      try {
        await subSubDir.create();
        fail('shoud fail');
      } on FileSystemException catch (e) {
        expect(e.status, FileSystemException.statusNotFound);
        // FileSystemException: Creation failed, path = '/media/ssd/devx/hg/dart-pkg/lib/fs_shim/test_out/io/dir/create_recursive/sub/subsub' (OS Error: No such file or directory, errno = 2)
        // FileSystemException: Creation failed, path = '/default/dir/create_recursive/sub/subsub' (OS Error: No such file or directory, errno = 2)
      }
      await subSubDir.create(recursive: true);
      await subSubDir.create(recursive: true);
      await subSubDir.create();
    });

    test('delete', () async {
      final dir = await ctx.prepare();

      final subDir = fs.directory(fs.path.join(dir.path, 'sub'));
      expect(await (await subDir.create()).exists(), isTrue);
      expect(await fs.isDirectory(subDir.path), isTrue);

      // delete
      expect(await (await subDir.delete()).exists(), isFalse);
      expect(await fs.isDirectory(subDir.path), isFalse);

      try {
        await subDir.delete();
        fail('shoud fail');
      } on FileSystemException catch (e) {
        expect(e.status, FileSystemException.statusNotFound);
        // FileSystemException: Deletion failed, path = '/media/ssd/devx/hg/dart-pkg/lib/fs_shim/test_out/io/dir/delete/sub' (OS Error: No such file or directory, errno = 2)
        // [404] FileSystemException: Deletion failed, path = '/idb_io/dir/delete/sub' (OS Error: No such file or directory, errno = 2)
      }
    });

    test('rename', () async {
      final directory = await ctx.prepare();

      final path = fs.path.join(directory.path, 'dir');
      final path2 = fs.path.join(directory.path, 'dir2');
      final dir = fs.directory(path);
      await dir.create();
      final dir2 = await dir.rename(path2) as Directory;
      expect(dir2.path, path2);
      expect(await dir.exists(), isFalse);
      expect(await dir2.exists(), isTrue);
      expect(await fs.isDirectory(dir2.path), isTrue);
    });

    test('rename_not_found', () async {
      final directory = await ctx.prepare();

      final path = fs.path.join(directory.path, 'dir');
      final path2 = fs.path.join(directory.path, 'dir2');
      final dir = fs.directory(path);
      try {
        await dir.rename(path2);
        fail('shoud fail');
      } on FileSystemException catch (e) {
        expect(e.status, FileSystemException.statusNotFound);
        // FileSystemException: Deletion failed, path = '/media/ssd/devx/hg/dart-pkg/lib/fs_shim/test_out/io/dir/delete/sub' (OS Error: No such file or directory, errno = 2)
        // [404] FileSystemException: Deletion failed, path = '/idb_io/dir/delete/sub' (OS Error: No such file or directory, errno = 2)
      }
    });

    test('rename_over_existing', () async {
      final directory = await ctx.prepare();

      final path = fs.path.join(directory.path, 'dir');
      final path2 = fs.path.join(directory.path, 'dir2');
      final dir = fs.directory(path);
      final dir2 = fs.directory(path2);
      await dir.create();
      await dir2.create();

      // Starting 2.16, this fails on windows only
      try {
        await dir.rename(path2);
        if (isIoWindows(ctx)) {
          fail('should fail');
        }
        expect(await dir.exists(), isFalse);
        expect(await dir2.exists(), isTrue);
      } on FileSystemException catch (e) {
        expect(isIoWindows(ctx), isTrue);
        //   [17] FileSystemException: Rename failed, path = 'D:\a\fs_shim.dart\fs_shim.dart\fs\.dart_tool\fs_shim\test\test12\dir' (OS Error: Cannot create a file when that file already exists.
        expect(e.status == FileSystemException.statusAlreadyExists, isTrue,
            reason: e.toString());
      }
    });

    // This fails on windows
    test('rename_over_existing_not_empty', () async {
      final directory = await ctx.prepare();

      final path = fs.path.join(directory.path, 'dir');
      final path2 = fs.path.join(directory.path, 'dir2');
      final dir = fs.directory(path);
      final subDir = fs.directory(fs.path.join(path2, 'sub'));
      await dir.create();
      await subDir.create(recursive: true);

      try {
        await dir.rename(path2);
        fail('should fail');
      } on FileSystemException catch (e) {
        // [39] FileSystemException: Rename failed, path = '/idb_io/dir/rename_over_existing_not_empty/dir' (OS Error: Directory not empty, errno = 39)
        //expect(e.status, FileSystemException.statusNotEmpty);
        // travis returns 17!
        expect(
            e.status == FileSystemException.statusNotEmpty ||
                e.status == FileSystemException.statusAlreadyExists,
            isTrue,
            reason: e.toString());
      }
    });

    test('rename_over_existing_different_type', () async {
      final directory = await ctx.prepare();

      final path = fs.path.join(directory.path, 'dir');
      final path2 = fs.path.join(directory.path, 'file');
      final dir = fs.directory(path);
      final file2 = fs.file(path2);
      await dir.create();
      await file2.create();

      try {
        await dir.rename(path2);
        fail('should fail');
      } on FileSystemException catch (e) {
        if (isIoWindows(ctx)) {
          expect(e.status, FileSystemException.statusAlreadyExists);
        } else {
          // [20] FileSystemException: Rename failed, path = '/media/ssd/devx/hg/dart-pkg/lib/fs_shim/test_out/io/dir/rename_over_existing_different_type/dir' (OS Error: Not a directory, errno = 20)
          // [20] FileSystemException: Rename failed, path = '/dir/rename_over_existing_different_type/dir' (OS Error: Not a directory, errno = 20)
          // On windows we have 193!
          expect(e.status, FileSystemException.statusNotADirectory);
        }
      }
    });

    test('rename_has_content', () async {
      final directory = await ctx.prepare();

      final path = fs.path.join(directory.path, 'dir');
      final path2 = fs.path.join(directory.path, 'dir2');
      final file = fs.file(fs.path.join(path, 'file'));
      final file2 = fs.file(fs.path.join(path2, 'file'));
      await file.create(recursive: true);
      final dir = fs.directory(path);
      final dir2 = await dir.rename(path2) as Directory;
      expect(dir2.path, path2);
      expect(await dir.exists(), isFalse);
      expect(await dir2.exists(), isTrue);
      expect(await fs.isDirectory(dir2.path), isTrue);
      // check file path is renamed correctly
      expect(await file.exists(), isFalse);
      expect(await file2.exists(), isTrue);
      expect(await fs.isFile(file2.path), isTrue);
    });

    test('rename_different_folder_parent_not_created', () async {
      final directory = await ctx.prepare();

      final path = fs.path.join(directory.path, 'dir');
      final path2 = fs.path.join(directory.path, 'dir2');
      final path3 = fs.path.join(path2, 'sub');
      final dir = fs.directory(path);
      await dir.create();

      try {
        await dir.rename(path3);
        fail('should fail');
      } on FileSystemException catch (e) {
        expect(e.status, FileSystemException.statusNotFound);
      }
    });

    test('rename_different_folder', () async {
      final directory = await ctx.prepare();

      final path = fs.path.join(directory.path, 'dir');
      final path2 = fs.path.join(directory.path, 'dir2');
      final path3 = fs.path.join(path2, 'sub');
      final dir = fs.directory(path);
      final dir2 = fs.directory(path2);
      final dir3 = fs.directory(path3);
      await dir.create();
      await dir2.create();

      await dir.rename(path3);
      expect(await dir.exists(), isFalse);
      expect(await dir3.exists(), isTrue);
    });

    test('delete_recursive', () async {
      final dir = await ctx.prepare();

      final subDir = fs.directory(fs.path.join(dir.path, 'sub'));
      final subSubDir = fs.directory(fs.path.join(subDir.path, 'subsub'));
      final subSubSubDir =
          fs.directory(fs.path.join(subSubDir.path, 'subsubsub'));

      expect(
          await (await subSubSubDir.create(recursive: true)).exists(), isTrue);
      expect(await subDir.exists(), isTrue);
      expect(await subSubDir.exists(), isTrue);

      try {
        await subDir.delete();
        fail('shoud fail');
      } on FileSystemException catch (e) {
        // Mac: errno 66 - not empty
        // FileSystemException: Deletion failed, path = '/media/ssd/devx/hg/dart-pkg/lib/fs_shim/test_out/io/dir/delete_recursive/sub' (OS Error: Directory not empty, errno = 39)
        // [39] FileSystemException: Deletion failed, path = '/default/dir/delete_recursive/sub' (OS Error: Directory not empty, errno = 39)
        expect(e.status, FileSystemException.statusNotEmpty);
      }

      await subDir.delete(recursive: true);
      expect(await subDir.exists(), isFalse);
      expect(await subSubDir.exists(), isFalse);
      expect(await subSubSubDir.exists(), isFalse);

      try {
        await subDir.delete();
        fail('shoud fail');
      } on FileSystemException catch (e) {
        expect(e.status, FileSystemException.statusNotFound);
        // FileSystemException: Deletion failed, path = '/media/ssd/devx/hg/dart-pkg/lib/fs_shim/test_out/io/dir/delete/sub' (OS Error: No such file or directory, errno = 2)
        // [404] FileSystemException: Deletion failed, path = '/idb_io/dir/delete/sub' (OS Error: No such file or directory, errno = 2)
      }
    });

    int indexOf(List<FileSystemEntity> list, FileSystemEntity entity) {
      for (var i = 0; i < list.length; i++) {
        if (list[i].path == entity.path) {
          return i;
        }
      }
      return -1;
    }

    FileSystemEntity? getInList(
        List<FileSystemEntity> list, FileSystemEntity entity) {
      for (var i = 0; i < list.length; i++) {
        if (list[i].path == entity.path) {
          return list[i];
        }
      }
      return null;
    }

    test('list', () async {
      final directory = await ctx.prepare();
      var list = await directory.list().toList();
      expect(list, isEmpty);

      // Create one two dirs
      final dir1 = fs.directory(fs.path.join(directory.path, 'dir1'));
      final dir2 = fs.directory(fs.path.join(directory.path, 'dir2'));
      // And one sub dir in dir1
      final subDir = fs.directory(fs.path.join(dir1.path, 'sub'));
      // And one file
      final file = fs.file(fs.path.join(subDir.path, 'file'));

      await file.create(recursive: true);
      await dir2.create();

      // not recursive
      list = await directory.list().toList();
      expect(list.length, 2);
      expect(indexOf(list, dir1), isNot(-1));
      expect(indexOf(list, dir2), isNot(-1));
      expect(getInList(list, dir2), const TypeMatcher<Directory>());

      // recursive
      list = await directory.list(recursive: true).toList();
      expect(list.length, 4);
      expect(indexOf(list, dir1), isNot(-1));
      expect(indexOf(list, dir1), lessThan(indexOf(list, subDir)));
      expect(indexOf(list, subDir), lessThan(indexOf(list, file)));
      expect(getInList(list, file), const TypeMatcher<File>());
      expect(indexOf(list, dir2), isNot(-1));
    });

    test('list_nodirectory', () async {
      final top = await ctx.prepare();
      final dir = childDirectory(top, 'dir');
      try {
        await dir.list().toList();
      } on FileSystemException catch (e) {
        expect(e.status, FileSystemException.statusNotFound);
      }
    });
  });
}
