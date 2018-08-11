// Copyright (c) 2015, <your name>. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library fs_shim.test.fs_shim_file_test;

import 'package:fs_shim/fs.dart';
import 'package:path/path.dart';

import 'test_common.dart';

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

  group('file', () {
    group('currentDir', () {
      test('writeAsString', () async {
        // direct file write, no preparation
        var fs = ctx.fs;
        await fs.file("file.tmp").writeAsString("context");
      }, skip: false);
    });
    test('new', () {
      File file = fs.file("dummy");
      expect(file.path, "dummy");
      expect(file.fs, fs);
      file = fs.file(r"\root/dummy");
      expect(file.path, r"\root/dummy");
      file = fs.file(r"\");
      expect(file.path, r"\");
      file = fs.file(r"");
      expect(file.path, r"");
      try {
        file = fs.file(null);
        fail("should fail");
      } on ArgumentError catch (_) {
        // Invalid argument(s): null is not a String
      }
    });

    test('toString', () {
      File file = fs.file("file");
      expect(file.toString(), "File: '${file.path}'");
    });

    test('absolute', () {
      File file = fs.file("dummy");
      expect(file.isAbsolute, isFalse);

      file = file.absolute;
      expect(file.isAbsolute, isTrue);
      expect(file.absolute.path, file.path);
    });

    test('parent', () {
      File file = fs.file(join(separator, "dummy"));
      if (!contextIsWindows) {
        // somehow absolute means more on windows
        expect(file.isAbsolute, isTrue);
        expect(file.parent.path, fs.directory('/').path);
      }
    });

    test('exists', () async {
      Directory dir = await ctx.prepare();
      File file = fs.file(join(dir.path, "file"));
      expect(await file.exists(), isFalse);
    });

    test('create', () async {
      Directory dir = await ctx.prepare();

      File file = fs.file(join(dir.path, "file"));
      expect(await file.exists(), isFalse);
      expect(await fs.isFile(file.path), isFalse);
      expect(await (await file.create()).exists(), isTrue);
      expect(await fs.isFile(file.path), isTrue);

      // second time fine too
      await file.create();
    });

    test('create_recursive', () async {
      Directory dir = await ctx.prepare();

      Directory subDir = fs.directory(join(dir.path, "sub"));

      File file = fs.file(join(subDir.path, "file"));

      try {
        await file.create();
        fail("shoud fail");
      } on FileSystemException catch (e) {
        _printErr(e);
        expect(e.status, FileSystemException.statusNotFound);
        // FileSystemException: Creation failed, path = '/media/ssd/devx/hg/dart-pkg/lib/fs_shim/test_out/io/dir/create_recursive/sub/subsub' (OS Error: No such file or directory, errno = 2)
        // FileSystemException: Creation failed, path = '/default/dir/create_recursive/sub/subsub' (OS Error: No such file or directory, errno = 2)
      }
      expect(await (await file.create(recursive: true)).exists(), isTrue);
      await file.create(recursive: true);
      await file.create();
    });

    test('delete_file', () async {
      Directory dir = await ctx.prepare();

      File file = fs.file(join(dir.path, "file"));
      expect(await (await file.create()).exists(), isTrue);
      expect(await fs.isFile(file.path), isTrue);

      // delete
      expect(await (await file.delete()).exists(), isFalse);
      expect(await fs.isFile(file.path), isFalse);

      try {
        await file.delete();
        fail("shoud fail");
      } on FileSystemException catch (e) {
        _printErr(e);
        expect(e.status, FileSystemException.statusNotFound);
        // FileSystemException: Deletion failed, path = '/media/ssd/devx/hg/dart-pkg/lib/fs_shim/test_out/io/dir/delete/sub' (OS Error: No such file or directory, errno = 2)
        // [404] FileSystemException: Deletion failed, path = '/idb_io/dir/delete/sub' (OS Error: No such file or directory, errno = 2)
      }
    });

    test('delete_file_recursive', () async {
      Directory dir = await ctx.prepare();

      File file = fs.file(join(dir.path, "file"));
      expect(await (await file.create()).exists(), isTrue);
      expect(await fs.isFile(file.path), isTrue);

      // delete
      expect(await (await file.delete(recursive: true)).exists(), isFalse);
      expect(await fs.isFile(file.path), isFalse);

      try {
        await file.delete();
        fail("shoud fail");
      } on FileSystemException catch (e) {
        _printErr(e);
        expect(e.status, FileSystemException.statusNotFound);
        // FileSystemException: Deletion failed, path = '/media/ssd/devx/hg/dart-pkg/lib/fs_shim/test_out/io/dir/delete/sub' (OS Error: No such file or directory, errno = 2)
        // [404] FileSystemException: Deletion failed, path = '/idb_io/dir/delete/sub' (OS Error: No such file or directory, errno = 2)
      }
    });

    test('rename_file', () async {
      Directory _dir = await ctx.prepare();

      String path = join(_dir.path, "file");
      String path2 = join(_dir.path, "file2");
      File file = fs.file(path);
      await file.create();
      File file2 = await file.rename(path2) as File;
      expect(file2.path, path2);
      expect(await file.exists(), isFalse);
      expect(await file2.exists(), isTrue);
      expect(await fs.isFile(file2.path), isTrue);
    });

    test('rename_notfound', () async {
      Directory _dir = await ctx.prepare();

      String path = join(_dir.path, "file");
      String path2 = join(_dir.path, "file2");
      File file = fs.file(path);
      try {
        await file.rename(path2);
        fail("shoud fail");
      } on FileSystemException catch (e) {
        expect(e.status, FileSystemException.statusNotFound);
        // FileSystemException: Deletion failed, path = '/media/ssd/devx/hg/dart-pkg/lib/fs_shim/test_out/io/dir/delete/sub' (OS Error: No such file or directory, errno = 2)
        // [404] FileSystemException: Deletion failed, path = '/idb_io/dir/delete/sub' (OS Error: No such file or directory, errno = 2)
      }
    });

    test('rename_with_content', () async {
      Directory _dir = await ctx.prepare();

      String path = join(_dir.path, "file");
      String path2 = join(_dir.path, "file2");
      File file = fs.file(path);
      await file.writeAsString("test", flush: true);
      File file2 = await file.rename(path2) as File;
      expect(file2.path, path2);
      expect(await file.exists(), isFalse);
      expect(await file2.exists(), isTrue);
      expect(await fs.isFile(file2.path), isTrue);
      expect(await file2.readAsString(), "test");
    });

    test('stat_file', () async {
      Directory _dir = await ctx.prepare();

      File file = fs.file(join(_dir.path, "file"));
      FileStat stat = await file.stat();
      expect(stat.type, FileSystemEntityType.notFound);
      expect(stat.size, -1);
      expect(stat.modified, null);

      await file.create();
      stat = await file.stat();
      expect(stat.type, FileSystemEntityType.file);
      expect(stat.size, 0);
      expect(stat.modified, isNotNull);

      await file.writeAsString("test", flush: true);
      stat = await file.stat();
      expect(stat.type, FileSystemEntityType.file);
      expect(stat.size, 4);
      expect(stat.modified, isNotNull);

      // rename
      file = await file.rename(join(_dir.path, "file2")) as File;
      stat = await file.stat();

      expect(stat.type, FileSystemEntityType.file);
      expect(stat.size, 4);
      expect(stat.modified, isNotNull);

      // copy
      file = await file.copy(join(_dir.path, "file3"));
      expect(file.path, endsWith("file3"));
      stat = await file.stat();
      expect(stat.type, FileSystemEntityType.file);
      expect(stat.size, 4);
      expect(stat.modified, isNotNull);
    });

    test('rename_over_existing_different_type', () async {
      Directory _dir = await ctx.prepare();

      String path = join(_dir.path, "dir");
      String path2 = join(_dir.path, "file");
      Directory dir = fs.directory(path);
      File file2 = fs.file(path2);
      await dir.create();
      await file2.create();

      try {
        await file2.rename(path);
        fail('should fail');
      } on FileSystemException catch (e) {
        if (isIoWindows(ctx)) {
          expect(e.status, FileSystemException.statusAccessError);
        } else {
          // [21] FileSystemException: Cannot rename file to '/media/ssd/devx/hg/dart-pkg/lib/fs_shim/test_out/io/file/rename_over_existing_different_type/dir', path = '/media/ssd/devx/hg/dart-pkg/lib/fs_shim/test_out/io/file/rename_over_existing_different_type/file' (OS Error: Is a directory, errno = 21)
          expect(e.status, FileSystemException.statusIsADirectory);
        }
      }
    });

    test('rename_over_existing_content', () async {
      Directory _dir = await ctx.prepare();

      String path = join(_dir.path, "file");
      String path2 = join(_dir.path, "file2");
      File file = fs.file(path);
      File file2 = fs.file(path2);
      await file.writeAsString("test", flush: true);
      await file2.writeAsString("test2", flush: true);
      file2 = await file.rename(path2) as File;
      expect(file2.path, path2);
      expect(await file.exists(), isFalse);
      expect(await file2.exists(), isTrue);
      expect(await fs.isFile(file2.path), isTrue);
      expect(await file2.readAsString(), "test");
    });

    test('copy', () async {
      Directory _dir = await ctx.prepare();

      String path = join(_dir.path, "file");
      String path2 = join(_dir.path, "file2");
      File file = fs.file(path);
      await file.create();
      File file2 = await file.copy(path2);
      expect(file2.path, path2);
      expect(await file.exists(), isTrue);
      expect(await file2.exists(), isTrue);
      expect(await fs.isFile(file2.path), isTrue);
    });

    test('copy_with_content', () async {
      Directory _dir = await ctx.prepare();

      String path = join(_dir.path, "file");
      String path2 = join(_dir.path, "file2");
      File file = fs.file(path);
      await file.writeAsString("test", flush: true);
      File file2 = await file.copy(path2);
      expect(file2.path, path2);
      expect(await file2.exists(), isTrue);
      expect(await fs.isFile(file2.path), isTrue);
      expect(await file.readAsString(), "test");
      expect(await file2.readAsString(), "test");
    });

    test('copy_overwrite_content', () async {
      Directory _dir = await ctx.prepare();

      String path = join(_dir.path, "file");
      String path2 = join(_dir.path, "file2");
      File file = fs.file(path);
      File file2 = fs.file(path2);
      await file.writeAsString("test", flush: true);
      await file2.writeAsString("test2", flush: true);
      file2 = await file.copy(path2);
      expect(file2.path, path2);
      expect(await file2.exists(), isTrue);
      expect(await fs.isFile(file2.path), isTrue);
      expect(await file.readAsString(), "test");
      expect(await file2.readAsString(), "test");
    });

    test('create_dir_or_file', () async {
      Directory _dir = await ctx.prepare();

      String path = join(_dir.path, "dir_or_file");

      File file = fs.file(path);
      Directory dir = fs.directory(path);
      expect(await (await file.create()).exists(), isTrue);
      await file.create();
      try {
        await dir.create();
        fail("should fail");
      } on FileSystemException catch (e) {
        _printErr(e);
        // [17] FileSystemException: Creation failed, path = '/media/ssd/devx/hg/dart-pkg/lib/fs_shim/test_out/io/file/create_dir_or_file/dir_or_file' (OS Error: File exists, errno = 17)
        // [17] FileSystemException: Creation failed, path = '/file/create_dir_or_file/dir_or_file' (OS Error: File exists, errno = 17)
        if (isIo(ctx) && !isIoWindows(ctx)) {
          // tested on linux
          expect(e.status, FileSystemException.statusNotADirectory,
              reason: e.toString());
        } else {
          expect(e.status, FileSystemException.statusAlreadyExists,
              reason: e.toString());
        }
      }

      // however this is fine!
      await dir.exists();
      await file.exists();

      try {
        await dir.delete();
        fail("should fail");
      } on FileSystemException catch (e) {
        _printErr(e);
        if (isIoWindows(ctx)) {
          expect(e.status, FileSystemException.statusNotFound);
        } else {
          // [20] FileSystemException: Deletion failed, path = '/media/ssd/devx/hg/dart-pkg/lib/fs_shim/test_out/io/file/create_dir_or_file/dir_or_file' (OS Error: Not a directory, errno = 20)
          // [20] FileSystemException: Deletion failed, path = '/file/create_dir_or_file/dir_or_file' (OS Error: Not a directory, errno = 20)
          expect(e.status, FileSystemException.statusNotADirectory);
        }
      }

      await file.delete();

      expect(await (await dir.create()).exists(), isTrue);
      await dir.create();
      try {
        await file.create();
        if (!isIoMac(ctx)) {
          fail("should fail");
        }
      } on FileSystemException catch (e) {
        _printErr(e);
        if (isIoWindows(ctx)) {
          expect(e.status, FileSystemException.statusAccessError);
        } else {
          // [21] FileSystemException: Cannot create file, path = '/media/ssd/devx/hg/dart-pkg/lib/fs_shim/test_out/io/file/create_dir_or_file/dir_or_file' (OS Error: Is a directory, errno = 21)
          // [21] FileSystemException: Creation failed, path = '/file/create_dir_or_file/dir_or_file' (OS Error: Is a directory, errno = 21)
          expect(e.status, FileSystemException.statusIsADirectory);
        }
      }

      try {
        await file.delete();
        fail("should fail");
      } on FileSystemException catch (e) {
        _printErr(e);
        if (isIoWindows(ctx)) {
          expect(e.status, FileSystemException.statusAccessError);
        } else {
          // [21] FileSystemException: Cannot delete file, path = '/media/ssd/devx/hg/dart-pkg/lib/fs_shim/test_out/io/file/create_dir_or_file/dir_or_file' (OS Error: Is a directory, errno = 21)
          // [20] FileSystemException: Deletion failed, path = '/file/create_dir_or_file/dir_or_file' (OS Error: Not a directory, errno = 20)
          expect(e.status, FileSystemException.statusIsADirectory);
        }
      }
    });

    test('simple_write_read', () async {
      Directory _dir = await ctx.prepare();
      File file = fs.file(join(_dir.path, "file"));
      await file.create();
      var sink = file.openWrite(mode: FileMode.write);
      sink.add('test'.codeUnits);
      await sink.close();
      List<int> content = [];
      await file.openRead().listen((List<int> data) {
        content.addAll(data);
      }).asFuture();
      expect(content, 'test'.codeUnits);

      content = [];
      await file.openRead(1).listen((List<int> data) {
        content.addAll(data);
      }).asFuture();
      expect(content, 'est'.codeUnits);

      content = [];
      await file.openRead(1, 3).listen((List<int> data) {
        content.addAll(data);
      }).asFuture();
      expect(content, 'es'.codeUnits);
    });

    test('read_not_found', () async {
      Directory _dir = await ctx.prepare();
      File file = fs.file(join(_dir.path, "file"));
      try {
        await file.openRead().listen((List<int> data) {
          //content.addAll(data);
        }).asFuture();
      } on FileSystemException catch (e) {
        // [2] FileSystemException: Cannot open file, path = '/media/ssd/devx/hg/dart-pkg/lib/fs_shim/test_out/io/file/read_not_found/file' (OS Error: No such file or directory, errno = 2)
        // [2] FileSystemException: Read failed, path = '/file/read_not_found/file' (OS Error: No such file or directory, errno = 2)
        _printErr(e);
        expect(e.status, FileSystemException.statusNotFound);
      }
    });

    test('write_bad_mode', () async {
      Directory _dir = await ctx.prepare();
      File file = fs.file(join(_dir.path, "file"));
      try {
        var sink = file.openWrite(mode: FileMode.read);
        sink.add('test'.codeUnits);
        await sink.close();
      } on ArgumentError catch (e) {
        _printErr(e);
      }
    });

    test('append_not_found', () async {
      Directory _dir = await ctx.prepare();
      File file = fs.file(join(_dir.path, "file"));
      var sink = file.openWrite(mode: FileMode.append);
      sink.add('test'.codeUnits);
      await sink.close();

      List<int> content = [];
      await file.openRead().listen((List<int> data) {
        content.addAll(data);
      }).asFuture();
      expect(content, 'test'.codeUnits);
    });

    test('write_not_found', () async {
      Directory _dir = await ctx.prepare();
      File file = fs.file(join(_dir.path, "file"));
      try {
        var sink = file.openWrite(mode: FileMode.append);
        sink.add('test'.codeUnits);
        await sink.close();
      } on FileSystemException catch (e) {
        // [2] FileSystemException: Cannot open file, path = '/media/ssd/devx/hg/dart-pkg/lib/fs_shim/test_out/io/file/read_not_found/file' (OS Error: No such file or directory, errno = 2)
        // [2] FileSystemException: Read failed, path = '/file/read_not_found/file' (OS Error: No such file or directory, errno = 2)
        _printErr(e);
      }

      List<int> content = [];
      await file.openRead().listen((List<int> data) {
        content.addAll(data);
      }).asFuture();
      expect(content, 'test'.codeUnits);
    });

    test('overwrite', () async {
      Directory _dir = await ctx.prepare();
      File file = fs.file(join(_dir.path, "file"));
      var sink = file.openWrite(mode: FileMode.write);
      sink.add('test'.codeUnits);
      await sink.close();

      List<int> content = [];
      await file.openRead().listen((List<int> data) {
        content.addAll(data);
      }).asFuture();
      expect(content, 'test'.codeUnits);

      sink = file.openWrite(mode: FileMode.write);
      sink.add('overwritten'.codeUnits);
      await sink.close();

      content = [];
      await file.openRead().listen((List<int> data) {
        content.addAll(data);
      }).asFuture();
      expect(content, 'overwritten'.codeUnits);
    });

    test('append', () async {
      Directory _dir = await ctx.prepare();
      File file = fs.file(join(_dir.path, "file"));
      var sink = file.openWrite(mode: FileMode.write);
      sink.add('test'.codeUnits);
      await sink.close();

      expect(await file.readAsBytes(), 'test'.codeUnits, reason: "readAsBytes");
      List<int> content = [];
      await file.openRead().listen((List<int> data) {
        content.addAll(data);
      }).asFuture();
      expect(content, 'test'.codeUnits);

      sink = file.openWrite(mode: FileMode.append);
      sink.add('append'.codeUnits);
      await sink.close();

      content = [];
      await file.openRead().listen((List<int> data) {
        content.addAll(data);
      }).asFuture();
      expect(content, 'testappend'.codeUnits);
    });

    test('write_on_dir', () async {
      Directory _dir = await ctx.prepare();
      var filePath = join(_dir.path, "file");
      Directory dir = fs.directory(filePath);
      File file = fs.file(filePath);

      await dir.create();

      var sink = file.openWrite(mode: FileMode.append);
      sink.add('test'.codeUnits);
      try {
        await sink.close();
      } on FileSystemException catch (e) {
        if (isIoWindows(ctx)) {
          expect(e.status, FileSystemException.statusAccessError);
        } else {
          expect(e.status, FileSystemException.statusIsADirectory);
          // [21] FileSystemException: Cannot open file, path = '/media/ssd/devx/hg/dart-pkg/lib/fs_shim/test_out/io/file/write_on_dir/file' (OS Error: Is a directory, errno = 21)
          // [21] FileSystemException: Write failed, path = '/file/write_on_dir/file' (OS Error: Is a directory, errno = 21)
        }
      }
    });

    test('read_write_bytes', () async {
      List<int> bytes = [0, 1, 2, 3];
      Directory _dir = await ctx.prepare();
      var filePath = join(_dir.path, "file");
      File file = fs.file(filePath);

      await file.writeAsBytes(bytes, flush: true);
      expect(await file.readAsBytes(), bytes);

      // overwrite
      await file.writeAsBytes(bytes, flush: true);
      expect(await file.readAsBytes(), bytes);

      // append
      await file.writeAsBytes(bytes, mode: FileMode.append, flush: true);
      expect(await file.readAsBytes(), [0, 1, 2, 3, 0, 1, 2, 3]);
    });

    test('read_write_string', () async {
      String text = "test";
      Directory _dir = await ctx.prepare();
      var filePath = join(_dir.path, "file");
      File file = fs.file(filePath);

      await file.writeAsString(text, flush: true);
      expect(await file.readAsString(), text);

      // overwrite
      await file.writeAsString(text, flush: true);
      expect(await file.readAsString(), text);

      // append
      await file.writeAsString(text, mode: FileMode.append, flush: true);
      expect(await file.readAsString(), "$text$text");
    });
  });
}
