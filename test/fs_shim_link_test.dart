// Copyright (c) 2015, <your name>. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library fs_shim.test.fs_shim_link_test;

import 'package:fs_shim/fs.dart';
import 'test_common.dart';
import 'package:path/path.dart';

main() {
  defineTests(memoryFileSystemTestContext);
}

FileSystemTestContext _ctx;
FileSystem get fs => _ctx.fs;

final bool _doPrintErr = false;
_printErr(e) {
  if (_doPrintErr) {
    print("${e} ${[e.runtimeType]}");
  }
}

void defineTests(FileSystemTestContext ctx) {
  _ctx = ctx;

  bool _linkSupported = fs.supportsLink;

  test('isSupported', () {
    expect(fs.supportsLink, _linkSupported);
  });
  if (_linkSupported) {
    group('link', () {
      test('new', () {
        Link link = fs.newLink("dummy");
        expect(link.path, "dummy");

        link = fs.newLink(r"\root/dummy");
        expect(link.path, r"\root/dummy");
        link = fs.newLink(r"\");
        expect(link.path, r"\");
        link = fs.newLink(r"");
        expect(link.path, r"");
        try {
          link = fs.newLink(null);
          fail("should fail");
        } on ArgumentError catch (_) {
          // Invalid argument(s): null is not a String
        }
      });
      test('absolute', () {
        Link link = fs.newLink("dummy");
        expect(link.isAbsolute, isFalse);

        link = link.absolute;
        expect(link.isAbsolute, isTrue);
        expect(link.absolute.path, link.path);
      });

      test('exists', () async {
        Directory dir = await ctx.prepare();
        Link file = fs.newLink(join(dir.path, "link"));
        expect(await file.exists(), isFalse);
      });

      solo_test('create', () async {
        Directory dir = await ctx.prepare();

        String target = "target";
        Link link = fs.newLink(join(dir.path, "link"));
        expect(await link.exists(), isFalse);
        expect(await fs.isLink(link.path), isFalse);
        expect(await (await link.create(target)).exists(), isTrue);
        expect(await fs.isLink(link.path), isTrue);

        // second time should fail
        try {
          await link.create(target);
        } on FileSystemException catch (e) {
          _printErr(e);
          expect(e.status, FileSystemException.statusAlreadyExists);
          // [17] FileSystemException: Cannot create link to target '/media/ssd/devx/git/github.com/tekartik/fs_shim.dart/test_out/io/link/create_file/target', path = '/media/ssd/devx/git/github.com/tekartik/fs_shim.dart/test_out/io/link/create_file/link' (OS Error: File exists, errno = 17) [FileSystemException]
        }
        // different target fails too
        try {
          await link.create("other_target");
        } on FileSystemException catch (e) {
          _printErr(e);
          expect(e.status, FileSystemException.statusAlreadyExists);
          // [17] FileSystemException: Cannot create link to target '/media/ssd/devx/git/github.com/tekartik/fs_shim.dart/test_out/io/link/create_file/target', path = '/media/ssd/devx/git/github.com/tekartik/fs_shim.dart/test_out/io/link/create_file/link' (OS Error: File exists, errno = 17) [FileSystemException]
        }
      });

      test('target', () async {
        Directory dir = await ctx.prepare();

        String target = "target";
        Link link = fs.newLink(join(dir.path, "link"));
        try {
          await link.target();
        } on FileSystemException catch (e) {
          _printErr(e);
          expect(e.status, FileSystemException.statusNotFound);
          // [2] FileSystemException: Cannot get target of link, path = '/media/ssd/devx/git/github.com/tekartik/fs_shim.dart/test_out/io/link/target/link' (OS Error: No such file or directory, errno = 2) [FileSystemExceptionImpl]
        }

        await link.create(target);

        expect(await link.target(), target);
      });

      test('create_file', () async {
        Directory dir = await ctx.prepare();

        String target = join(dir.path, "target");
        /*File file = */
        fs.newFile(target)..create();
        Link link = fs.newLink(join(dir.path, "link"));
        expect(await link.exists(), isFalse);
        expect(await fs.isLink(link.path), isFalse);
        expect(await (await link.create(target)).exists(), isTrue);
        expect(await fs.isLink(link.path), isTrue);

        // second time should fail
        try {
          await link.create(target);
          fail("shoud fail");
        } on FileSystemException catch (e) {
          _printErr(e);
          expect(e.status, FileSystemException.statusAlreadyExists);
          // [17] FileSystemException: Cannot create link to target '/media/ssd/devx/git/github.com/tekartik/fs_shim.dart/test_out/io/link/create_file/target', path = '/media/ssd/devx/git/github.com/tekartik/fs_shim.dart/test_out/io/link/create_file/link' (OS Error: File exists, errno = 17) [FileSystemException]
        }

        // different target fails too
        try {
          await link.create(join(dir.path, "other_target"));
          fail("shoud fail");
        } on FileSystemException catch (e) {
          _printErr(e);
          expect(e.status, FileSystemException.statusAlreadyExists);
          // [17] FileSystemException: Cannot create link to target '/media/ssd/devx/git/github.com/tekartik/fs_shim.dart/test_out/io/link/create_file/target', path = '/media/ssd/devx/git/github.com/tekartik/fs_shim.dart/test_out/io/link/create_file/link' (OS Error: File exists, errno = 17) [FileSystemException]
        }
      });

      test('create_recursive', () async {
        Directory dir = await ctx.prepare();

        Directory subDir = fs.newDirectory(join(dir.path, "sub"));

        Link link = fs.newLink(join(subDir.path, "file"));

        try {
          await link.create('target');
          fail("shoud fail");
        } on FileSystemException catch (e) {
          _printErr(e);
          expect(e.status, FileSystemException.statusNotFound);
          // [2] FileSystemException: Cannot create link to target 'target', path = '/media/ssd/devx/git/github.com/tekartik/fs_shim.dart/test_out/io/link/create_recursive/sub/file' (OS Error: No such file or directory, errno = 2) [FileSystemExceptionImpl]
        }
        expect(await (await link.create('target', recursive: true)).exists(),
            isTrue);
      });

      test('delete', () async {
        Directory dir = await ctx.prepare();

        Link link = fs.newLink(join(dir.path, "file"));
        expect(await (await link.create('target')).exists(), isTrue);
        expect(await fs.isLink(link.path), isTrue);

        // delete
        expect(await (await link.delete()).exists(), isFalse);
        expect(await fs.isLink(link.path), isFalse);

        try {
          await link.delete();
          fail("shoud fail");
        } on FileSystemException catch (e) {
          _printErr(e);
          // expect(e.status, FileSystemException.statusNotFound);
          // <not parsed on linux: 22> FileSystemException: Cannot delete link, path = '/media/ssd/devx/git/github.com/tekartik/fs_shim.dart/test_out/io/link/delete/file' (OS Error: Invalid argument, errno = 22) [FileSystemExceptionImpl]
        }
      });

      test('rename', () async {
        Directory _dir = await ctx.prepare();

        String path = join(_dir.path, "link");
        String path2 = join(_dir.path, "link2");
        Link link = fs.newLink(path);
        await link.create('target');
        Link link2 = await link.rename(path2);
        expect(link2.path, path2);
        expect(await link.exists(), isFalse);
        expect(await link2.exists(), isTrue);
        expect(await fs.isLink(link2.path), isTrue);
      });

      test('rename_notfound', () async {
        Directory _dir = await ctx.prepare();

        String path = join(_dir.path, "link");
        String path2 = join(_dir.path, "link2");
        Link file = fs.newLink(path);
        try {
          await file.rename(path2);
          fail("shoud fail");
        } on FileSystemException catch (e) {
          _printErr(e);
          // <22> not parsed invalid argument FileSystemException: Cannot rename link to '/media/ssd/devx/git/github.com/tekartik/fs_shim.dart/test_out/io/link/rename_notfound/link2', path = '/media/ssd/devx/git/github.com/tekartik/fs_shim.dart/test_out/io/link/rename_notfound/link' (OS Error: Invalid argument, errno = 22) [FileSystemExceptionImpl]
        }
      });

      test('file_follow_links', () async {
        Directory _dir = await ctx.prepare();
        File file = fs.newFile(join(_dir.path, 'file'));
        Link link = await fs.newLink(join(_dir.path, "link")).create(file.path);

        expect(await fs.type(link.path, followLinks: false),
            FileSystemEntityType.LINK);
        expect(await fs.type(link.path, followLinks: true),
            FileSystemEntityType.NOT_FOUND);

        await file.create();

        expect(await fs.type(link.path, followLinks: false),
            FileSystemEntityType.LINK);
        expect(await fs.type(link.path, followLinks: true),
            FileSystemEntityType.FILE);
      });

      test('link_read_string', () async {
        String text = "test";
        Directory _dir = await ctx.prepare();
        var filePath = join(_dir.path, "file");
        File file = fs.newFile(filePath);
        await file.writeAsString(text, flush: true);
        // check content
        expect(await file.readAsString(), text);

        // create a link to the file
        Link link = await fs.newLink(join(_dir.path, "link")).create(filePath);
        expect(await fs.isLink(link.path), isTrue);

        // check again content
        expect(await file.readAsString(), text);

        // and a file object on the link
        file = fs.newFile(link.path);
        expect(await file.readAsString(), text);
      });

      test('link_write_string', () async {
        String text = "test";
        Directory _dir = await ctx.prepare();
        var filePath = join(_dir.path, "file");
        File file = fs.newFile(filePath);
        ;

        // create a link to the file
        Link link = await fs.newLink(join(_dir.path, "link")).create(filePath);

        expect(await fs.isLink(link.path), isTrue);

        // and a file object on the link
        File linkFile = fs.newFile(link.path);
        await linkFile.writeAsString(text, flush: true);
        expect(await linkFile.readAsString(), text);
        expect(await file.readAsString(), text);

        expect(await fs.isLink(link.path), isTrue);
        expect(await fs.isLink(linkFile.path), isTrue);
        expect(await fs.isLink(file.path), isFalse);
        expect(await fs.isFile(file.path), isTrue);
        expect(await fs.isFile(link.path), isTrue);
        expect(await fs.isFile(linkFile.path), isTrue);
      });
    });

    /*
  skip_group('file', () {





    test('rename_with_content', () async {
      Directory _dir = await ctx.prepare();

      String path = join(_dir.path, "file");
      String path2 = join(_dir.path, "file2");
      File file = fs.newFile(path);
      await file.writeAsString("test", flush: true);
      File file2 = await file.rename(path2);
      expect(file2.path, path2);
      expect(await file.exists(), isFalse);
      expect(await file2.exists(), isTrue);
      expect(await fs.isFile(file2.path), isTrue);
      expect(await file2.readAsString(), "test");
    });

    test('stat', () async {
      Directory _dir = await ctx.prepare();

      File file = fs.newFile(join(_dir.path, "file"));
      FileStat stat = await file.stat();
      expect(stat.type, FileSystemEntityType.NOT_FOUND);
      expect(stat.size, -1);
      expect(stat.modified, null);

      await file.create();
      stat = await file.stat();
      expect(stat.type, FileSystemEntityType.FILE);
      expect(stat.size, 0);
      expect(stat.modified, isNotNull);

      await file.writeAsString("test", flush: true);
      stat = await file.stat();
      expect(stat.type, FileSystemEntityType.FILE);
      expect(stat.size, 4);
      expect(stat.modified, isNotNull);

      // rename
      file = await file.rename(join(_dir.path, "file2"));
      stat = await file.stat();
      expect(stat.type, FileSystemEntityType.FILE);
      expect(stat.size, 4);
      expect(stat.modified, isNotNull);

      // copy
      file = await file.copy(join(_dir.path, "file3"));
      stat = await file.stat();
      expect(stat.type, FileSystemEntityType.FILE);
      expect(stat.size, 4);
      expect(stat.modified, isNotNull);
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
      File file = fs.newFile(path);
      File file2 = fs.newFile(path2);
      await file.writeAsString("test", flush: true);
      await file2.writeAsString("test2", flush: true);
      file2 = await file.rename(path2);
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
      File file = fs.newFile(path);
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
      File file = fs.newFile(path);
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
      File file = fs.newFile(path);
      File file2 = fs.newFile(path2);
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

      File file = fs.newFile(path);
      Directory dir = fs.newDirectory(path);
      expect(await (await file.create()).exists(), isTrue);
      await file.create();
      try {
        await dir.create();
        fail("should fail");
      } on FileSystemException catch (e) {
        _printErr(e);
        // [17] FileSystemException: Creation failed, path = '/media/ssd/devx/hg/dart-pkg/lib/fs_shim/test_out/io/file/create_dir_or_file/dir_or_file' (OS Error: File exists, errno = 17)
        // [17] FileSystemException: Creation failed, path = '/file/create_dir_or_file/dir_or_file' (OS Error: File exists, errno = 17)
        expect(e.status, FileSystemException.statusAlreadyExists);
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
      File file = fs.newFile(join(_dir.path, "file"));
      await file.create();
      var sink = file.openWrite(mode: FileMode.WRITE);
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
      File file = fs.newFile(join(_dir.path, "file"));
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
      File file = fs.newFile(join(_dir.path, "file"));
      try {
        var sink = file.openWrite(mode: FileMode.READ);
        sink.add('test'.codeUnits);
        await sink.close();
      } on ArgumentError catch (e) {
        _printErr(e);
      }
    });

    test('append_not_found', () async {
      Directory _dir = await ctx.prepare();
      File file = fs.newFile(join(_dir.path, "file"));
      var sink = file.openWrite(mode: FileMode.APPEND);
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
      File file = fs.newFile(join(_dir.path, "file"));
      try {
        var sink = file.openWrite(mode: FileMode.APPEND);
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
      File file = fs.newFile(join(_dir.path, "file"));
      var sink = file.openWrite(mode: FileMode.WRITE);
      sink.add('test'.codeUnits);
      await sink.close();

      List<int> content = [];
      await file.openRead().listen((List<int> data) {
        content.addAll(data);
      }).asFuture();
      expect(content, 'test'.codeUnits);

      sink = file.openWrite(mode: FileMode.WRITE);
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
      File file = fs.newFile(join(_dir.path, "file"));
      var sink = file.openWrite(mode: FileMode.WRITE);
      sink.add('test'.codeUnits);
      await sink.close();

      List<int> content = [];
      await file.openRead().listen((List<int> data) {
        content.addAll(data);
      }).asFuture();
      expect(content, 'test'.codeUnits);

      sink = file.openWrite(mode: FileMode.APPEND);
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
      Directory dir = fs.newDirectory(filePath);
      File file = fs.newFile(filePath);

      await dir.create();

      var sink = file.openWrite(mode: FileMode.APPEND);
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
      File file = fs.newFile(filePath);

      await file.writeAsBytes(bytes, flush: true);
      expect(await file.readAsBytes(), bytes);

      // overwrite
      await file.writeAsBytes(bytes, flush: true);
      expect(await file.readAsBytes(), bytes);

      // append
      await file.writeAsBytes(bytes, mode: FileMode.APPEND, flush: true);
      expect(await file.readAsBytes(), [0, 1, 2, 3, 0, 1, 2, 3]);
    });

    test('read_write_string', () async {
      String text = "test";
      Directory _dir = await ctx.prepare();
      var filePath = join(_dir.path, "file");
      File file = fs.newFile(filePath);

      await file.writeAsString(text, flush: true);
      expect(await file.readAsString(), text);

      // overwrite
      await file.writeAsString(text, flush: true);
      expect(await file.readAsString(), text);

      // append
      await file.writeAsString(text, mode: FileMode.APPEND, flush: true);
      expect(await file.readAsString(), "$text$text");
    });
  });
  */
  }
}
