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

  test('supportsLink', () {
    expect(fs.supportsLink, _linkSupported);
  });
  test('supportsFileLink', () {
    // currently only windows io does not
    if (isIoWindows(ctx)) {
      expect(fs.supportsFileLink, isFalse);
    } else {
      expect(fs.supportsFileLink, isTrue);
    }
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

      test('create', () async {
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

        if (isIoWindows(ctx)) {
          // on io windows link are absolute
          expect(await link.target(), join(dir.path, target));
        } else {
          expect(await link.target(), target);
        }
      });

      test('link_target', () async {
        Directory dir = await ctx.prepare();

        String target = "target";
        Link link = fs.newLink(join(dir.path, "link"));
        await link.create(target);
        Link link2 = fs.newLink(join(dir.path, "link2"));
        await link2.create(link.path);

        expect(await link2.target(), link.path);
      });

      test('create_file', () async {
        Directory dir = await ctx.prepare();

        String target = join(dir.path, "target");
        /*File file = */
        File file = fs.newFile(target);
        await file.create();
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

      test('create_link_file', () async {
        Directory dir = await ctx.prepare();

        File file = fs.newFile(join(dir.path, "file"));
        Link link = fs.newLink(join(dir.path, "link"));

        if (isIoWindows(ctx)) {
          try {
            await link.create(file.path);
          } catch (_) {
            print(_);
          }
        } else {
          await link.create(file.path);
          File linkFile = fs.newFile(link.path);

          await linkFile.create();

          expect(await fs.isLink(link.path), isTrue);
          expect(await fs.isFile(link.path), isTrue);
          expect(await fs.isFile(file.path), isTrue);
        }
      });

      test('create_dir', () async {
        Directory top = await ctx.prepare();

        String target = join(top.path, "target");
        /*File file = */
        Directory dir = fs.newDirectory(target);
        await dir.create();
        Link link = fs.newLink(join(top.path, "link"));
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
          await link.create(join(top.path, "other_target"));
          fail("shoud fail");
        } on FileSystemException catch (e) {
          _printErr(e);
          expect(e.status, FileSystemException.statusAlreadyExists);
          // [17] FileSystemException: Cannot create link to target '/media/ssd/devx/git/github.com/tekartik/fs_shim.dart/test_out/io/link/create_file/target', path = '/media/ssd/devx/git/github.com/tekartik/fs_shim.dart/test_out/io/link/create_file/link' (OS Error: File exists, errno = 17) [FileSystemException]
        }
      });

      test('create_link_dir', () async {
        Directory top = await ctx.prepare();

        Directory dir = fs.newDirectory(join(top.path, "dir"));
        Link link = fs.newLink(join(top.path, "link"));
        await link.create(dir.path);
        Directory linkDir = fs.newDirectory(link.path);

        // This fails on linux!
        try {
          await linkDir.create();
          fail("should fail");
        } on FileSystemException catch (e) {
          _printErr(e);
          if (isIo(ctx)) {
            // win, linux, mac
            expect(e.status, FileSystemException.statusNotFound);
          } else {
            // idb: err 17
            expect(e.status, FileSystemException.statusAlreadyExists);
          }
        }

        expect(await fs.isLink(link.path), isTrue);
        expect(await fs.isDirectory(link.path), isFalse);
        expect(await fs.isDirectory(dir.path), isFalse);
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
          if (isIo(ctx)) {
            // win, linux, mac
            // FileSystemException: Cannot delete link, path = 'C:\devx\git\github.com\tekartik\fs_shim.dart\test_out\io\link\delete\file' (OS Error: Le fichier ou rÃ©pertoire nâ€™est pas un point dâ€™analyse., errno = 4390)
            expect(e.status, FileSystemException.statusInvalidArgument);
          } else {
            // idb
            expect(e.status, FileSystemException.statusNotFound);
            // <not parsed on linux: 22> FileSystemException: Cannot delete link, path = '/media/ssd/devx/git/github.com/tekartik/fs_shim.dart/test_out/io/link/delete/file' (OS Error: Invalid argument, errno = 22) [FileSystemExceptionImpl]
          }
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
          if (isIo(ctx)) {
            expect(e.status, FileSystemException.statusInvalidArgument);
          } else {
            // mac, idb
            expect(e.status, FileSystemException.statusNotFound);
            // <22> not parsed invalid argument FileSystemException: Cannot rename link to '/media/ssd/devx/git/github.com/tekartik/fs_shim.dart/test_out/io/link/rename_notfound/link2', path = '/media/ssd/devx/git/github.com/tekartik/fs_shim.dart/test_out/io/link/rename_notfound/link' (OS Error: Invalid argument, errno = 22) [FileSystemExceptionImpl]
          }
        }
      });

      test('file_follow_links', () async {
        if (fs.supportsFileLink) {
          Directory _dir = await ctx.prepare();
          File file = fs.newFile(join(_dir.path, 'file'));
          Link link =
              await fs.newLink(join(_dir.path, "link")).create(file.path);

          expect(await fs.type(link.path, followLinks: false),
              FileSystemEntityType.LINK);
          expect(await fs.type(link.path, followLinks: true),
              FileSystemEntityType.NOT_FOUND);

          await file.create();

          expect(await fs.type(link.path, followLinks: false),
              FileSystemEntityType.LINK);
          expect(await fs.type(link.path, followLinks: true),
              FileSystemEntityType.FILE);
        }
      });

      test('dir_follow_links', () async {
        Directory top = await ctx.prepare();
        Directory dir = fs.newDirectory(join(top.path, 'dir'));
        Link link = await fs.newLink(join(top.path, "link")).create(dir.path);

        expect(await fs.type(link.path, followLinks: false),
            FileSystemEntityType.LINK);
        // on windows following a missing link return the link
        if (isIoWindows(ctx)) {
          expect(await fs.type(link.path, followLinks: true),
              FileSystemEntityType.LINK);
        } else {
          expect(await fs.type(link.path, followLinks: true),
              FileSystemEntityType.NOT_FOUND);
        }

        await dir.create();

        expect(await fs.type(link.path, followLinks: false),
            FileSystemEntityType.LINK);
        expect(await fs.type(link.path, followLinks: true),
            FileSystemEntityType.DIRECTORY);
      });

      test('link_read_string', () async {
        if (fs.supportsFileLink) {
          String text = "test";
          Directory _dir = await ctx.prepare();
          var filePath = join(_dir.path, "file");
          File file = fs.newFile(filePath);
          await file.writeAsString(text, flush: true);
          // check content
          expect(await file.readAsString(), text);

          // create a link to the file
          Link link =
              await fs.newLink(join(_dir.path, "link")).create(filePath);
          expect(await fs.isLink(link.path), isTrue);

          // check again content
          expect(await file.readAsString(), text);

          // and a file object on the link
          file = fs.newFile(link.path);
          expect(await file.readAsString(), text);
        }
      });

      test('link_write_string', () async {
        if (fs.supportsFileLink) {
          String text = "test";
          Directory _dir = await ctx.prepare();
          var filePath = join(_dir.path, "file");
          File file = fs.newFile(filePath);
          ;

          // create a link to the file
          Link link =
              await fs.newLink(join(_dir.path, "link")).create(filePath);

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
        }
      });

      test('link_to_subfile', () async {
        if (fs.supportsFileLink) {
          String text = "test";
          Directory top = await ctx.prepare();

          Directory dir = fs.newDirectory(join(top.path, 'dir'));
          File file = fs.newFile(join(dir.path, 'file'));

          Link link = fs.newLink(join(top.path, "link"));
          await link.create('dir/file');
          expect(await link.target(), join('dir', 'file'));

          await file.create(recursive: true);
          expect(await fs.isFile(link.path), isTrue);
          expect(await fs.isLink(link.path), isTrue);

          File linkFile = fs.newFile(link.path);
          await linkFile.writeAsString(text, flush: true);
          expect(await linkFile.readAsString(), text);
          expect(await file.readAsString(), text);
        }
      });

      test('link_to_subdir', () async {
        Directory top = await ctx.prepare();

        Directory dir = fs.newDirectory(join(top.path, 'dir'));
        Directory sub = fs.newDirectory(join(dir.path, 'sub'));

        Link link = fs.newLink(join(top.path, "link"));
        await link.create('dir/sub');

        if (isIoWindows(ctx)) {
          // absolute on windows
          expect(await link.target(), join(dir.path, 'sub'));
        } else {
          expect(await link.target(), join('dir', 'sub'));
        }

        await sub.create(recursive: true);
        expect(await fs.isDirectory(link.path), isTrue);
        expect(await fs.isLink(link.path), isTrue);
      });

      test('link_to_subfile_create', () async {
        if (fs.supportsFileLink) {
          String text = "test";
          Directory top = await ctx.prepare();

          Directory dir = fs.newDirectory(join(top.path, 'dir'));
          await dir.create();
          File file = fs.newFile(join(dir.path, 'file'));

          Link link = fs.newLink(join(top.path, "link"));
          await link.create('dir/file');
          expect(await link.target(), join('dir', 'file'));

          File linkFile = fs.newFile(link.path);
          await linkFile.writeAsString(text, flush: true);
          expect(await linkFile.readAsString(), text);
          expect(await file.readAsString(), text);
        }
      });

      test('link_to_topdir', () async {
        String text = "test";
        Directory top = await ctx.prepare();

        Directory dir = fs.newDirectory(join(top.path, 'dir'));
        File file = fs.newFile(join(dir.path, 'file'));

        Link link = fs.newLink(join(top.path, "link"));
        await link.create('dir');

        if (isIoWindows(ctx)) {
          // absollute on windows
          expect(await link.target(), dir.path);
        } else {
          expect(await link.target(), 'dir');
        }

        await file.create(recursive: true);
        File linkFile = fs.newFile(join(link.path, 'file'));
        expect(await fs.isFile(linkFile.path), isTrue);
        expect(await fs.isLink(linkFile.path), isFalse);

        // Create a fil object
        expect(linkFile.absolute.path, linkFile.path);
        await linkFile.writeAsString(text, flush: true);
        expect(await linkFile.readAsString(), text);
        expect(await file.readAsString(), text);
      });

      test('link_append_string', () async {
        if (fs.supportsFileLink) {
          String text = "test";
          Directory _dir = await ctx.prepare();
          var filePath = join(_dir.path, "file");
          File file = fs.newFile(filePath);

          // create a link to the file
          Link link =
              await fs.newLink(join(_dir.path, "link")).create(filePath);

          expect(await fs.isLink(link.path), isTrue);

          await file.writeAsString("te", flush: true);

          // and a file object on the link
          File linkFile = fs.newFile(link.path);
          // Append data
          var sink = linkFile.openWrite(mode: FileMode.APPEND);
          sink.add("st".codeUnits);
          await sink.close();
          expect(await linkFile.readAsString(), text);
          expect(await file.readAsString(), text);

          expect(await fs.isLink(link.path), isTrue);
          expect(await fs.isLink(linkFile.path), isTrue);
          expect(await fs.isLink(file.path), isFalse);
          expect(await fs.isFile(file.path), isTrue);
          expect(await fs.isFile(link.path), isTrue);
          expect(await fs.isFile(linkFile.path), isTrue);
        }
      });

      test('file_stat', () async {
        if (fs.supportsFileLink) {
          Directory _dir = await ctx.prepare();

          Link link = fs.newLink(join(_dir.path, "link"));
          FileStat stat = await link.stat();
          expect(stat.type, FileSystemEntityType.NOT_FOUND);
          expect(stat.size, -1);
          expect(stat.modified, null);

          await link.create("file");
          stat = await link.stat();
          expect(stat.type, FileSystemEntityType.NOT_FOUND);
          expect(stat.size, -1);
          expect(stat.modified, isNull);

          File file = fs.newFile(join(_dir.path, 'file'));

          await file.writeAsString("test", flush: true);
          stat = await link.stat();
          expect(stat.type, FileSystemEntityType.FILE);
          expect(stat.size, 4);
          expect(stat.modified, isNotNull);

          // rename
          link = await link.rename(join(_dir.path, "link2"));
          stat = await link.stat();
          expect(stat.type, FileSystemEntityType.FILE);
          expect(stat.size, 4);
          expect(stat.modified, isNotNull);
        }
      });

      test('dir_stat', () async {
        Directory top = await ctx.prepare();

        Link link = fs.newLink(join(top.path, "link"));
        FileStat stat = await link.stat();
        expect(stat.type, FileSystemEntityType.NOT_FOUND);
        expect(stat.size, -1);
        expect(stat.modified, null);

        await link.create("dir");
        stat = await link.stat();
        // on windows it assumes a directort
        if (isIoWindows(ctx)) {
          expect(stat.type, FileSystemEntityType.LINK);
          expect(stat.size, 0);
          expect(stat.modified, isNotNull);
        } else {
          expect(stat.type, FileSystemEntityType.NOT_FOUND);
          expect(stat.size, -1);
          expect(stat.modified, isNull);
        }

        Directory dir = fs.newDirectory(join(top.path, 'dir'));
        await dir.create();
        stat = await link.stat();

        // on windows we get the link stat..
        if (isIoWindows(ctx)) {
          expect(stat.type, FileSystemEntityType.LINK);
        } else {
          expect(stat.type, FileSystemEntityType.DIRECTORY);
        }
        expect(stat.size, isNot(-1));
        expect(stat.size, isNotNull);
        expect(stat.modified, isNotNull);
      });

      test('rename_over_existing_different_type', () async {
        Directory _dir = await ctx.prepare();

        String path = join(_dir.path, "dir");
        String path2 = join(_dir.path, "link");
        Directory dir = fs.newDirectory(path);
        Link link = fs.newLink(path2);
        await dir.create();
        await link.create("target");

        try {
          await link.rename(path);
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

      test('create_dir_or_file', () async {
        Directory top = await ctx.prepare();

        String path = join(top.path, "dir_or_file");

        File file = fs.newFile(path);
        Directory dir = fs.newDirectory(path);
        Link link = fs.newLink(path);
        await dir.create();
        try {
          await link.create("target");
          fail("should fail");
        } on FileSystemException catch (e) {
          _printErr(e);
          if (isIoWindows(ctx)) {
            // [17] FileSystemException: Cannot create link to target '\??\C:\devx\git\github.com\tekartik\fs_shim.dart\test_out\io\link\create_dir_or_file\target', path = 'C:\devx\git\github.com\tekartik\fs_shim.dart\test_out\io\link\create_dir_or_file\dir_or_file' (OS Error: Impossible de crÃ©er un fichier dÃ©jÃ  existant.      , errno = 183)
            expect(e.status, FileSystemException.statusAlreadyExists);
          } else {
            // [17] FileSystemException: Creation failed, path = '/file/create_dir_or_file/dir_or_file' (OS Error: File exists, errno = 17)
            expect(e.status, FileSystemException.statusAlreadyExists);
          }
        }

        // however this is fine!
        await dir.exists();
        await file.exists();
        await link.exists();

        try {
          await link.delete();
          fail("should fail");
        } on FileSystemException catch (e) {
          _printErr(e);
          // Invalid argument for link

          if (isIoWindows(ctx)) {
            // FileSystemException: Cannot delete link, path = 'C:\devx\git\github.com\tekartik\fs_shim.dart\test_out\io\link\create_dir_or_file\dir_or_file' (OS Error: Le fichier ou rÃ©pertoire nâ€™est pas un point dâ€™analyse., errno = 4390)
            expect(e.status, FileSystemException.statusInvalidArgument);
          } else {
            // [20] FileSystemException: Deletion failed, path = '/media/ssd/devx/hg/dart-pkg/lib/fs_shim/test_out/io/file/create_dir_or_file/dir_or_file' (OS Error: Not a directory, errno = 20)
            // [20] FileSystemException: Deletion failed, path = '/file/create_dir_or_file/dir_or_file' (OS Error: Not a directory, errno = 20)
            if (isIo(ctx)) {
              // linux/android
              expect(e.status, FileSystemException.statusInvalidArgument);
            } else {
              // mac, idb
              expect(e.status, FileSystemException.statusIsADirectory);
            }
          }
        }

        await dir.delete();

        await dir.create();
        try {
          await link.create("target");
          fail("should fail");
        } on FileSystemException catch (e) {
          _printErr(e);
          if (isIoWindows(ctx)) {
            // [17] FileSystemException: Cannot create link to target '\??\C:\devx\git\github.com\tekartik\fs_shim.dart\test_out\io\link\create_dir_or_file\target', path = 'C:\devx\git\github.com\tekartik\fs_shim.dart\test_out\io\link\create_dir_or_file\dir_or_file' (OS Error: Impossible de crÃ©er un fichier dÃ©jÃ  existant., errno = 183)
            expect(e.status, FileSystemException.statusAlreadyExists);
          } else {
            // [21] FileSystemException: Cannot create file, path = '/media/ssd/devx/hg/dart-pkg/lib/fs_shim/test_out/io/file/create_dir_or_file/dir_or_file' (OS Error: Is a directory, errno = 21)
            // [21] FileSystemException: Creation failed, path = '/file/create_dir_or_file/dir_or_file' (OS Error: Is a directory, errno = 21)
            expect(e.status, FileSystemException.statusAlreadyExists);
          }
        }

        try {
          await link.delete();
          fail("should fail");
        } on FileSystemException catch (e) {
          _printErr(e);
          if (isIo(ctx)) {
            // win, mac, linux
            expect(e.status, FileSystemException.statusInvalidArgument);
          } else {
            // idb
            expect(e.status, FileSystemException.statusIsADirectory);
          }
        }

        // however this is fine!
        await dir.exists();
        await file.exists();
        await link.exists();
      });
    });

    /*
  skip_group('file', () {





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
