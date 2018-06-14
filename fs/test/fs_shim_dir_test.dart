// Copyright (c) 2015, <your name>. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library fs_shim.test.fs_shim_dir_test;

import 'package:fs_shim/fs.dart';
import 'package:path/path.dart';

import 'test_common.dart';

main() {
  defineTests(memoryFileSystemTestContext);
}

FileSystemTestContext _ctx;
FileSystem get fs => _ctx.fs;
void defineTests(FileSystemTestContext ctx) {
  _ctx = ctx;

  group('dir', () {
    test('new', () {
      Directory dir = fs.newDirectory("dummy");
      expect(dir.path, "dummy");
      dir = fs.newDirectory(r"\root/dummy");
      expect(dir.path, r"\root/dummy");
      dir = fs.newDirectory(r"\");
      expect(dir.path, r"\");
      dir = fs.newDirectory(r"");
      expect(dir.path, r"");
      try {
        dir = fs.newDirectory(null);
        fail("should fail");
      } on ArgumentError catch (_) {
        // Invalid argument(s): null is not a String
      }
    });

    test('toString', () {
      Directory dir = fs.newDirectory("dir");
      expect(dir.toString(), "Directory: '${dir.path}'");
    });

    test('absolute', () {
      Directory dir = fs.newDirectory("dummy");
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
      Directory dir = await ctx.prepare();
      expect(await dir.exists(), isTrue);
      Directory subDir = fs.newDirectory(join(dir.path, "sub"));
      expect(await subDir.exists(), isFalse);
    });

    test('create', () async {
      Directory dir = await ctx.prepare();

      Directory subDir = fs.newDirectory(join(dir.path, "sub"));
      expect(await subDir.exists(), isFalse);
      expect(await fs.isDirectory(subDir.path), isFalse);
      expect(await (await subDir.create()).exists(), isTrue);
      expect(await fs.isDirectory(subDir.path), isTrue);

      // second time fine too
      await subDir.create();
    });

    test('stat', () async {
      Directory _dir = await ctx.prepare();

      Directory dir = fs.newDirectory(join(_dir.path, "dir"));
      FileStat stat = await dir.stat();
      //print(stat);
      expect(stat.type, FileSystemEntityType.NOT_FOUND);
      expect(stat.size, -1);
      expect(stat.modified, null);

      await dir.create();
      stat = await dir.stat();
      //print(stat);
      expect(stat.type, FileSystemEntityType.DIRECTORY);
      expect(stat.size, isNot(-1));
      expect(stat.size, isNotNull);
      expect(stat.modified, isNotNull);
    });

    test('create_recursive', () async {
      Directory dir = await ctx.prepare();

      Directory subDir = fs.newDirectory(join(dir.path, "sub"));
      Directory subSubDir = fs.newDirectory(join(subDir.path, "subsub"));

      try {
        await subSubDir.create();
        fail("shoud fail");
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
      Directory dir = await ctx.prepare();

      Directory subDir = fs.newDirectory(join(dir.path, "sub"));
      expect(await (await subDir.create()).exists(), isTrue);
      expect(await fs.isDirectory(subDir.path), isTrue);

      // delete
      expect(await (await subDir.delete()).exists(), isFalse);
      expect(await fs.isDirectory(subDir.path), isFalse);

      try {
        await subDir.delete();
        fail("shoud fail");
      } on FileSystemException catch (e) {
        expect(e.status, FileSystemException.statusNotFound);
        // FileSystemException: Deletion failed, path = '/media/ssd/devx/hg/dart-pkg/lib/fs_shim/test_out/io/dir/delete/sub' (OS Error: No such file or directory, errno = 2)
        // [404] FileSystemException: Deletion failed, path = '/idb_io/dir/delete/sub' (OS Error: No such file or directory, errno = 2)
      }
    });

    test('rename', () async {
      Directory _dir = await ctx.prepare();

      String path = join(_dir.path, "dir");
      String path2 = join(_dir.path, "dir2");
      Directory dir = fs.newDirectory(path);
      await dir.create();
      Directory dir2 = await dir.rename(path2) as Directory;
      expect(dir2.path, path2);
      expect(await dir.exists(), isFalse);
      expect(await dir2.exists(), isTrue);
      expect(await fs.isDirectory(dir2.path), isTrue);
    });

    test('rename_not_found', () async {
      Directory _dir = await ctx.prepare();

      String path = join(_dir.path, "dir");
      String path2 = join(_dir.path, "dir2");
      Directory dir = fs.newDirectory(path);
      try {
        await dir.rename(path2);
        fail("shoud fail");
      } on FileSystemException catch (e) {
        expect(e.status, FileSystemException.statusNotFound);
        // FileSystemException: Deletion failed, path = '/media/ssd/devx/hg/dart-pkg/lib/fs_shim/test_out/io/dir/delete/sub' (OS Error: No such file or directory, errno = 2)
        // [404] FileSystemException: Deletion failed, path = '/idb_io/dir/delete/sub' (OS Error: No such file or directory, errno = 2)
      }
    });

    test('rename_over_existing', () async {
      Directory _dir = await ctx.prepare();

      String path = join(_dir.path, "dir");
      String path2 = join(_dir.path, "dir2");
      Directory dir = fs.newDirectory(path);
      Directory dir2 = fs.newDirectory(path2);
      await dir.create();
      await dir2.create();

      await dir.rename(path2);
      expect(await dir.exists(), isFalse);
      expect(await dir2.exists(), isTrue);
    });

    // This fails on windows
    test('rename_over_existing_not_empty', () async {
      Directory _dir = await ctx.prepare();

      String path = join(_dir.path, "dir");
      String path2 = join(_dir.path, "dir2");
      Directory dir = fs.newDirectory(path);
      Directory subDir = fs.newDirectory(join(path2, "sub"));
      await dir.create();
      await subDir.create(recursive: true);

      try {
        await dir.rename(path2);
        if (!isIoWindows(ctx)) {
          fail('should fail');
        }
      } on FileSystemException catch (e) {
        expect(isIoWindows(ctx), isFalse);
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
      Directory _dir = await ctx.prepare();

      String path = join(_dir.path, "dir");
      String path2 = join(_dir.path, "file");
      Directory dir = fs.newDirectory(path);
      File file2 = fs.newFile(path2);
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
      Directory _dir = await ctx.prepare();

      String path = join(_dir.path, "dir");
      String path2 = join(_dir.path, "dir2");
      File file = fs.newFile(join(path, "file"));
      File file2 = fs.newFile(join(path2, "file"));
      await file.create(recursive: true);
      Directory dir = fs.newDirectory(path);
      Directory dir2 = await dir.rename(path2) as Directory;
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
      Directory _dir = await ctx.prepare();

      String path = join(_dir.path, "dir");
      String path2 = join(_dir.path, "dir2");
      String path3 = join(path2, "sub");
      Directory dir = fs.newDirectory(path);
      await dir.create();

      try {
        await dir.rename(path3);
        fail('should fail');
      } on FileSystemException catch (e) {
        expect(e.status, FileSystemException.statusNotFound);
      }
    });

    test('rename_different_folder', () async {
      Directory _dir = await ctx.prepare();

      String path = join(_dir.path, "dir");
      String path2 = join(_dir.path, "dir2");
      String path3 = join(path2, "sub");
      Directory dir = fs.newDirectory(path);
      Directory dir2 = fs.newDirectory(path2);
      Directory dir3 = fs.newDirectory(path3);
      await dir.create();
      await dir2.create();

      await dir.rename(path3);
      expect(await dir.exists(), isFalse);
      expect(await dir3.exists(), isTrue);
    });

    test('delete_recursive', () async {
      Directory dir = await ctx.prepare();

      Directory subDir = fs.newDirectory(join(dir.path, "sub"));
      Directory subSubDir = fs.newDirectory(join(subDir.path, "subsub"));
      Directory subSubSubDir =
          fs.newDirectory(join(subSubDir.path, "subsubsub"));

      expect(
          await (await subSubSubDir.create(recursive: true)).exists(), isTrue);
      expect(await subDir.exists(), isTrue);
      expect(await subSubDir.exists(), isTrue);

      try {
        await subDir.delete();
        fail("shoud fail");
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
        fail("shoud fail");
      } on FileSystemException catch (e) {
        expect(e.status, FileSystemException.statusNotFound);
        // FileSystemException: Deletion failed, path = '/media/ssd/devx/hg/dart-pkg/lib/fs_shim/test_out/io/dir/delete/sub' (OS Error: No such file or directory, errno = 2)
        // [404] FileSystemException: Deletion failed, path = '/idb_io/dir/delete/sub' (OS Error: No such file or directory, errno = 2)
      }
    });

    int indexOf(List<FileSystemEntity> list, FileSystemEntity entity) {
      for (int i = 0; i < list.length; i++) {
        if (list[i].path == entity.path) {
          return i;
        }
      }
      return -1;
    }

    FileSystemEntity getInList(
        List<FileSystemEntity> list, FileSystemEntity entity) {
      for (int i = 0; i < list.length; i++) {
        if (list[i].path == entity.path) {
          return list[i];
        }
      }
      return null;
    }

    test('list', () async {
      Directory _dir = await ctx.prepare();
      List<FileSystemEntity> list = await _dir.list().toList();
      expect(list, isEmpty);

      // Create one two dirs
      Directory dir1 = fs.newDirectory(join(_dir.path, "dir1"));
      Directory dir2 = fs.newDirectory(join(_dir.path, "dir2"));
      // And one sub dir in dir1
      Directory subDir = fs.newDirectory(join(dir1.path, "sub"));
      // And one file
      File file = fs.newFile(join(subDir.path, "file"));

      await file.create(recursive: true);
      await dir2.create();

      // not recursive
      list = await _dir.list().toList();
      expect(list.length, 2);
      expect(indexOf(list, dir1), isNot(-1));
      expect(indexOf(list, dir2), isNot(-1));
      expect(getInList(list, dir2), new isInstanceOf<Directory>());

      // recursive
      list = await _dir.list(recursive: true).toList();
      expect(list.length, 4);
      expect(indexOf(list, dir1), isNot(-1));
      expect(indexOf(list, dir1), lessThan(indexOf(list, subDir)));
      expect(indexOf(list, subDir), lessThan(indexOf(list, file)));
      expect(getInList(list, file), new isInstanceOf<File>());
      expect(indexOf(list, dir2), isNot(-1));
    });

    test('list_no_dir', () async {
      Directory top = await ctx.prepare();
      Directory dir = childDirectory(top, "dir");
      try {
        await dir.list().toList();
      } on FileSystemException catch (e) {
        expect(e.status, FileSystemException.statusNotFound);
      }
    });
  });
}
