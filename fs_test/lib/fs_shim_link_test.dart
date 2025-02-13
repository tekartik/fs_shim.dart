// Copyright (c) 2015, <your name>. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library;

import 'package:dev_test/test.dart';
// ignore_for_file: unnecessary_import
import 'package:fs_shim/fs.dart';
import 'package:path/path.dart' as p;

import 'fs_shim_file_stat_test.dart';
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
  final linkSupported = fs.supportsLink;

  test('supportsLink', () {
    expect(fs.supportsLink, linkSupported);
  });
  if (linkSupported) {
    group('link', () {
      test('new', () {
        var link = fs.link('dummy');
        expect(link.path, 'dummy');

        link = fs.link(r'\root/dummy');
        expect(link.path, r'\root/dummy');
        link = fs.link(r'\');
        expect(link.path, r'\');
        link = fs.link(r'');
        expect(link.path, r'');
      });

      test('toString', () {
        final link = fs.link('link');
        expect(link.toString(), "Link: '${link.path}'");
      });

      test('absolute', () {
        var link = fs.link('dummy');
        expect(link.isAbsolute, isFalse);

        link = link.absolute;
        expect(link.isAbsolute, isTrue);
        expect(link.absolute.path, link.path);
      });

      test('exists', () async {
        final dir = await ctx.prepare();
        final file = fs.link(fs.path.join(dir.path, 'link'));
        expect(await file.exists(), isFalse);
      });

      test('create', () async {
        final dir = await ctx.prepare();

        final target = 'target';
        final link = fs.link(fs.path.join(dir.path, 'link'));
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
          await link.create('other_target');
        } on FileSystemException catch (e) {
          _printErr(e);
          expect(e.status, FileSystemException.statusAlreadyExists);
          // [17] FileSystemException: Cannot create link to target '/media/ssd/devx/git/github.com/tekartik/fs_shim.dart/test_out/io/link/create_file/target', path = '/media/ssd/devx/git/github.com/tekartik/fs_shim.dart/test_out/io/link/create_file/link' (OS Error: File exists, errno = 17) [FileSystemException]
        }
      });

      test('target', () async {
        final dir = await ctx.prepare();

        final target = 'target';
        final link = fs.link(fs.path.join(dir.path, 'link'));
        try {
          await link.target();
        } on FileSystemException catch (e) {
          _printErr(e);
          expect(e.status, FileSystemException.statusNotFound);
          // [2] FileSystemException: Cannot get target of link, path = '/media/ssd/devx/git/github.com/tekartik/fs_shim.dart/test_out/io/link/target/link' (OS Error: No such file or directory, errno = 2) [FileSystemExceptionImpl]
        }

        await link.create(target);

        try {
          expect(await link.target(), target);
        } catch (e) {
          if (isIoWindows(ctx)) {
            // on io windows link were absolute
            // This did no happen when tested on 2019-09-05
            expect(await link.target(), p.join(dir.path, target));
            rethrow;
          }
        }
      });

      test('link_target', () async {
        final dir = await ctx.prepare();

        final target = 'target';
        final link = fs.link(fs.path.join(dir.path, 'link'));
        await link.create(target);
        final link2 = fs.link(fs.path.join(dir.path, 'link2'));
        await link2.create(link.path);

        expect(await link2.target(), link.path);
      });

      test('create_file', () async {
        final dir = await ctx.prepare();

        final target = fs.path.join(dir.path, 'target');
        /*File file = */
        final file = fs.file(target);
        await file.create();
        final link = fs.link(fs.path.join(dir.path, 'link'));
        expect(await link.exists(), isFalse);
        expect(await fs.isLink(link.path), isFalse);
        expect(await (await link.create(target)).exists(), isTrue);
        expect(await fs.isLink(link.path), isTrue);

        // second time should fail
        try {
          await link.create(target);
          fail('shoud fail');
        } on FileSystemException catch (e) {
          _printErr(e);
          expect(e.status, FileSystemException.statusAlreadyExists);
          // [17] FileSystemException: Cannot create link to target '/media/ssd/devx/git/github.com/tekartik/fs_shim.dart/test_out/io/link/create_file/target', path = '/media/ssd/devx/git/github.com/tekartik/fs_shim.dart/test_out/io/link/create_file/link' (OS Error: File exists, errno = 17) [FileSystemException]
        }

        // different target fails too
        try {
          await link.create(fs.path.join(dir.path, 'other_target'));
          fail('shoud fail');
        } on FileSystemException catch (e) {
          _printErr(e);
          expect(e.status, FileSystemException.statusAlreadyExists);
          // [17] FileSystemException: Cannot create link to target '/media/ssd/devx/git/github.com/tekartik/fs_shim.dart/test_out/io/link/create_file/target', path = '/media/ssd/devx/git/github.com/tekartik/fs_shim.dart/test_out/io/link/create_file/link' (OS Error: File exists, errno = 17) [FileSystemException]
        }
      });

      test('create_link_file', () async {
        final dir = await ctx.prepare();

        final file = fs.file(fs.path.join(dir.path, 'file'));
        final link = fs.link(fs.path.join(dir.path, 'link'));

        if (isIoWindows(ctx)) {
          try {
            await link.create(file.path);
          } catch (e) {
            // ignore: avoid_print
            print(e);
          }
        } else {
          await link.create(file.path);
          final linkFile = fs.file(link.path);

          await linkFile.create();

          expect(await fs.isLink(link.path), isTrue);
          expect(await fs.isFile(link.path), isTrue);
          expect(await fs.isFile(file.path), isTrue);
        }
      });

      test('createdirectory', () async {
        final top = await ctx.prepare();

        final target = fs.path.join(top.path, 'target');
        /*File file = */
        final dir = fs.directory(target);
        await dir.create();
        final link = fs.link(fs.path.join(top.path, 'link'));
        expect(await link.exists(), isFalse);
        expect(await fs.isLink(link.path), isFalse);
        expect(await (await link.create(target)).exists(), isTrue);
        expect(await fs.isLink(link.path), isTrue);

        // second time should fail
        try {
          await link.create(target);
          fail('shoud fail');
        } on FileSystemException catch (e) {
          _printErr(e);
          expect(e.status, FileSystemException.statusAlreadyExists);
          // [17] FileSystemException: Cannot create link to target '/media/ssd/devx/git/github.com/tekartik/fs_shim.dart/test_out/io/link/create_file/target', path = '/media/ssd/devx/git/github.com/tekartik/fs_shim.dart/test_out/io/link/create_file/link' (OS Error: File exists, errno = 17) [FileSystemException]
        }

        // different target fails too
        try {
          await link.create(fs.path.join(top.path, 'other_target'));
          fail('shoud fail');
        } on FileSystemException catch (e) {
          _printErr(e);

          if (isIoWindows(ctx)) {
            // [5] FileSystemException: Cannot create link to target 'C:\opt\devx\git\github.com\tekartik\fs_shim.dart\fs\.dart_tool\fs_shim\test\io\link\createdirectory\other_target', path = 'C:\opt\devx\git\github.com\tekartik\fs_shim.dart\fs\.dart_tool\fs_shim\test\io\link\createdirectory\link' (OS Error: Access is denied. errno = 5) [FileSystemExceptionImpl]
            expect(e.status, FileSystemException.statusAccessError);
          } else {
            // [17] FileSystemException: Cannot create link to target '/media/ssd/devx/git/github.com/tekartik/fs_shim.dart/test_out/io/link/create_file/target', path = '/media/ssd/devx/git/github.com/tekartik/fs_shim.dart/test_out/io/link/create_file/link' (OS Error: File exists, errno = 17) [FileSystemException]
            expect(e.status, FileSystemException.statusAlreadyExists);
          }
        }
      });

      test('create_linkdirectory', () async {
        final top = await ctx.prepare();

        final dir = fs.directory(fs.path.join(top.path, 'dir'));
        final link = fs.link(fs.path.join(top.path, 'link'));
        await link.create(dir.path);
        final linkDir = fs.directory(link.path);

        // This fails on linux!
        try {
          await linkDir.create();
          fail('should fail');
        } on FileSystemException catch (e) {
          _printErr(e);
          if (isIo(ctx)) {
            // win, linux, mac
            try {
              expect(e.status, FileSystemException.statusNotFound);
            } catch (te) {
              if (isIoWindows(ctx)) {
                // [17] FileSystemException: Creation failed, path = 'C:\opt\devx\git\github.com\tekartik\fs_shim.dart\fs\.dart_tool\fs_shim\test\io\link\create_linkdirectory\link' (OS Error: Cannot create a file when that file already exists.
                //, errno = 183) [FileSystemExceptionImpl]
                expect(e.status, FileSystemException.statusAlreadyExists);
              } else {
                rethrow;
              }
            }
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
        final dir = await ctx.prepare();

        final subDir = fs.directory(fs.path.join(dir.path, 'sub'));

        final link = fs.link(fs.path.join(subDir.path, 'file'));

        try {
          await link.create('target');
          fail('shoud fail');
        } on FileSystemException catch (e) {
          _printErr(e);
          expect(e.status, FileSystemException.statusNotFound);
          // [2] FileSystemException: Cannot create link to target 'target', path = '/media/ssd/devx/git/github.com/tekartik/fs_shim.dart/test_out/io/link/create_recursive/sub/file' (OS Error: No such file or directory, errno = 2) [FileSystemExceptionImpl]
        }
        expect(
          await (await link.create('target', recursive: true)).exists(),
          isTrue,
        );
      });

      test('delete', () async {
        final dir = await ctx.prepare();

        final link = fs.link(fs.path.join(dir.path, 'file'));
        expect(await (await link.create('target')).exists(), isTrue);
        expect(await fs.isLink(link.path), isTrue);

        // delete
        expect(await (await link.delete()).exists(), isFalse);
        expect(await fs.isLink(link.path), isFalse);

        try {
          await link.delete();
          fail('shoud fail');
        } on FileSystemException catch (e) {
          _printErr(e);
          if (isIoWindows(ctx)) {
            expect(e.status, FileSystemException.statusInvalidArgument);
          } else {
            expect(e.status, FileSystemException.statusNotFound);
          }
          /*
          if (isIo(ctx)) {
            // win, linux, mac
            // FileSystemException: Cannot delete link, path = 'C:\devx\git\github.com\tekartik\fs_shim.dart\test_out\io\link\delete\file' (OS Error: Le fichier ou rÃ©pertoire nâ€™est pas un point dâ€™analyse., errno = 4390)
            expect(e.status, FileSystemException.statusInvalidArgument);
          } else {
            // idb
            expect(e.status, FileSystemException.statusNotFound);
            // <not parsed on linux: 22> FileSystemException: Cannot delete link, path = '/media/ssd/devx/git/github.com/tekartik/fs_shim.dart/test_out/io/link/delete/file' (OS Error: Invalid argument, errno = 22) [FileSystemExceptionImpl]
          }
          */
        }
      });

      test('rename', () async {
        final directory = await ctx.prepare();

        final path = fs.path.join(directory.path, 'link');
        final path2 = fs.path.join(directory.path, 'link2');
        final link = fs.link(path);
        await link.create('target');
        final link2 = await link.rename(path2);
        expect(link2.path, path2);
        expect(await link.exists(), isFalse);
        expect(await link2.exists(), isTrue);
        expect(await fs.isLink(link2.path), isTrue);
      });

      test('rename_not_found', () async {
        final directory = await ctx.prepare();

        final path = fs.path.join(directory.path, 'link');
        final path2 = fs.path.join(directory.path, 'link2');
        final file = fs.link(path);
        try {
          await file.rename(path2);
          fail('shoud fail');
        } on FileSystemException catch (e) {
          _printErr(e);
          expect(e.status, FileSystemException.statusNotFound);
          /*
          if (isIo(ctx) && !isIoWindows(ctx)) {
            expect(e.status, FileSystemException.statusInvalidArgument);
          } else {
            // mac, windows, idb
            expect(e.status, FileSystemException.statusNotFound);
            // <22> not parsed invalid argument FileSystemException: Cannot rename link to '/media/ssd/devx/git/github.com/tekartik/fs_shim.dart/test_out/io/link/rename_notfound/link2', path = '/media/ssd/devx/git/github.com/tekartik/fs_shim.dart/test_out/io/link/rename_notfound/link' (OS Error: Invalid argument, errno = 22) [FileSystemExceptionImpl]
          }
          */
        }
      });

      test('file_follow_links', () async {
        if (fs.supportsFileLink) {
          final directory = await ctx.prepare();
          final file = fs.file(fs.path.join(directory.path, 'file'));
          final link = await fs
              .link(fs.path.join(directory.path, 'link'))
              .create(file.path);

          expect(
            await fs.type(link.path, followLinks: false),
            FileSystemEntityType.link,
          );
          expect(
            await fs.type(link.path, followLinks: true),
            FileSystemEntityType.notFound,
          );

          await file.create();

          expect(
            await fs.type(link.path, followLinks: false),
            FileSystemEntityType.link,
          );
          expect(
            await fs.type(link.path, followLinks: true),
            FileSystemEntityType.file,
          );
        }
      });

      test('dir_follow_links', () async {
        final top = await ctx.prepare();
        final dir = fs.directory(fs.path.join(top.path, 'dir'));
        final link = await fs
            .link(fs.path.join(top.path, 'link'))
            .create(dir.path);

        expect(
          await fs.type(link.path, followLinks: false),
          FileSystemEntityType.link,
        );
        // on windows following a missing link return the link
        // ignore: dead_code
        if (isIoWindows(ctx) && false) {
          // Fixed since dart 3.4.0
          expect(
            await fs.type(link.path, followLinks: true),
            FileSystemEntityType.link,
          );
        } else {
          expect(
            await fs.type(link.path, followLinks: true),
            FileSystemEntityType.notFound,
          );
        }

        await dir.create();

        expect(
          await fs.type(link.path, followLinks: false),
          FileSystemEntityType.link,
        );
        if (isIoWindows(ctx)) {
          // Since dart 3.4.0
          expect(
            await fs.type(link.path, followLinks: true),
            FileSystemEntityType.notFound,
          );
        } else {
          expect(
            await fs.type(link.path, followLinks: true),
            FileSystemEntityType.directory,
          );
        }
      });

      test('link_read_string', () async {
        if (fs.supportsFileLink) {
          final text = 'test';
          final directory = await ctx.prepare();
          var filePath = fs.path.join(directory.path, 'file');
          var file = fs.file(filePath);
          await file.writeAsString(text, flush: true);
          // check content
          expect(await file.readAsString(), text);

          // create a link to the file
          final link = await fs
              .link(fs.path.join(directory.path, 'link'))
              .create(filePath);
          expect(await fs.isLink(link.path), isTrue);

          // check again content
          expect(await file.readAsString(), text);

          // and a file object on the link
          file = fs.file(link.path);
          expect(await file.readAsString(), text);
        }
      });

      test('link_write_string', () async {
        if (fs.supportsFileLink) {
          final text = 'test';
          final directory = await ctx.prepare();
          var filePath = fs.path.join(directory.path, 'file');
          final file = fs.file(filePath);

          // create a link to the file
          final link = await fs
              .link(fs.path.join(directory.path, 'link'))
              .create(filePath);

          expect(await fs.isLink(link.path), isTrue);

          // and a file object on the link
          final linkFile = fs.file(link.path);
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
          final text = 'test';
          final top = await ctx.prepare();

          final dir = fs.directory(fs.path.join(top.path, 'dir'));
          final file = fs.file(fs.path.join(dir.path, 'file'));

          final link = fs.link(fs.path.join(top.path, 'link'));
          await link.create('dir/file');
          expect(await link.target(), fs.path.join('dir', 'file'));

          await file.create(recursive: true);
          expect(await fs.isFile(link.path), isTrue);
          expect(await fs.isLink(link.path), isTrue);

          final linkFile = fs.file(link.path);
          await linkFile.writeAsString(text, flush: true);
          expect(await linkFile.readAsString(), text);
          expect(await file.readAsString(), text);
        }
      });

      test('link_to_subdir', () async {
        final top = await ctx.prepare();

        final dir = fs.directory(fs.path.join(top.path, 'dir'));
        final sub = fs.directory(fs.path.join(dir.path, 'sub'));

        final link = fs.link(fs.path.join(top.path, 'link'));
        await link.create(fs.path.join('dir', 'sub'));

        // 2019-09-06 fixed
        expect(await link.target(), fs.path.join('dir', 'sub'));

        await sub.create(recursive: true);
        if (isIoWindows(ctx)) {
          expect(await fs.isDirectory(link.path), isFalse);
        } else {
          expect(await fs.isDirectory(link.path), isTrue);
        }
        expect(await fs.isLink(link.path), isTrue);
      });

      test('link_to_subfile_create', () async {
        if (fs.supportsFileLink) {
          final text = 'test';
          final top = await ctx.prepare();

          final dir = fs.directory(fs.path.join(top.path, 'dir'));
          await dir.create();
          final file = fs.file(fs.path.join(dir.path, 'file'));

          final link = fs.link(fs.path.join(top.path, 'link'));
          await link.create('dir/file');
          expect(await link.target(), fs.path.join('dir', 'file'));

          final linkFile = fs.file(link.path);
          await linkFile.writeAsString(text, flush: true);
          expect(await linkFile.readAsString(), text);
          expect(await file.readAsString(), text);
        }
      });

      test('link_to_topdir', () async {
        final text = 'test';
        final top = await ctx.prepare();

        final dir = fs.directory(fs.path.join(top.path, 'dir'));
        final file = fs.file(fs.path.join(dir.path, 'file'));

        final link = fs.link(fs.path.join(top.path, 'link'));
        await link.create('dir');

        expect(await link.target(), 'dir');

        await file.create(recursive: true);
        final linkFile = fs.file(fs.path.join(link.path, 'file'));
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
          final text = 'test';
          final directory = await ctx.prepare();
          var filePath = fs.path.join(directory.path, 'file');
          final file = fs.file(filePath);

          // create a link to the file
          final link = await fs
              .link(fs.path.join(directory.path, 'link'))
              .create(filePath);

          expect(await fs.isLink(link.path), isTrue);

          await file.writeAsString('te', flush: true);

          // and a file object on the link
          final linkFile = fs.file(link.path);
          // Append data
          var sink = linkFile.openWrite(mode: FileMode.append);
          sink.add('st'.codeUnits);
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
          final directory = await ctx.prepare();

          var link = fs.link(fs.path.join(directory.path, 'link'));
          var stat = await link.stat();
          expect(stat.type, FileSystemEntityType.notFound);
          expect(stat.size, -1);
          expectNotFoundDateTime(stat.modified);

          await link.create('file');
          stat = await link.stat();
          expect(stat.type, FileSystemEntityType.notFound);
          expect(stat.size, -1);
          expectNotFoundDateTime(stat.modified);

          final file = fs.file(fs.path.join(directory.path, 'file'));

          await file.writeAsString('test', flush: true);
          stat = await link.stat();
          expect(stat.type, FileSystemEntityType.file);
          expect(stat.size, 4);
          expect(stat.modified, isNotNull);

          // rename
          link = await link.rename(fs.path.join(directory.path, 'link2'));
          stat = await link.stat();
          expect(stat.type, FileSystemEntityType.file);
          expect(stat.size, 4);
          expect(stat.modified, isNotNull);
        }
      });

      test('dir_stat', () async {
        final top = await ctx.prepare();

        final link = fs.link(fs.path.join(top.path, 'link'));
        var stat = await link.stat();
        expect(stat.type, FileSystemEntityType.notFound);
        expect(stat.size, -1);
        expectNotFoundDateTime(stat.modified);

        await link.create('dir');
        stat = await link.stat();
        // on windows it assumes a directort
        if (isIoWindows(ctx)) {
          /*
          expect(stat.type, FileSystemEntityType.LINK);
          expect(stat.size, 0);
          expect(stat.modified, isNotNull);
          */
        } else {
          expect(stat.type, FileSystemEntityType.notFound);
          expect(stat.size, -1);
          expectNotFoundDateTime(stat.modified);
        }

        final dir = fs.directory(fs.path.join(top.path, 'dir'));
        await dir.create();
        stat = await link.stat();

        // on windows we get the link stat..
        if (isIoWindows(ctx)) {
          expect(stat.type, FileSystemEntityType.notFound);
          expect(stat.size, -1);
        } else {
          expect(stat.type, FileSystemEntityType.directory);
          expect(stat.size, isNot(-1));
        }

        expect(stat.size, isNotNull);
        expect(stat.modified, isNotNull);
      });

      test('rename_over_existing_different_type', () async {
        final directory = await ctx.prepare();

        final path = fs.path.join(directory.path, 'dir');
        final path2 = fs.path.join(directory.path, 'link');
        final dir = fs.directory(path);
        final link = fs.link(path2);
        await dir.create();
        await link.create('target');

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

      test('createdirectory_or_file', () async {
        final top = await ctx.prepare();

        final path = fs.path.join(top.path, 'dir_or_file');

        final file = fs.file(path);
        final dir = fs.directory(path);
        final link = fs.link(path);
        await dir.create();
        try {
          await link.create('target');
          fail('should fail');
        } on FileSystemException catch (e) {
          _printErr(e);
          try {
            if (isIoWindows(ctx)) {
              // [17] FileSystemException: Cannot create link to target '\??\C:\devx\git\github.com\tekartik\fs_shim.dart\test_out\io\link\createdirectory_or_file\target', path = 'C:\devx\git\github.com\tekartik\fs_shim.dart\test_out\io\link\createdirectory_or_file\dir_or_file' (OS Error: Impossible de crÃ©er un fichier dÃ©jÃ  existant.      , errno = 183)
              expect(e.status, FileSystemException.statusAlreadyExists);
            } else {
              // [17] FileSystemException: Creation failed, path = '/file/createdirectory_or_file/dir_or_file' (OS Error: File exists, errno = 17)
              expect(e.status, FileSystemException.statusAlreadyExists);
            }
          } catch (te) {
            if (isIoWindows(ctx)) {
              // [5] FileSystemException: Cannot create link to target 'target', path = 'C:\opt\devx\git\github.com\tekartik\fs_shim.dart\fs\.dart_tool\fs_shim\test\io\link\createdirectory_or_file\dir_or_file' (OS Error: Access is denied.
              //, errno = 5) [FileSystemExceptionImpl]
              expect(e.status, FileSystemException.statusAccessError);
            } else {
              rethrow;
            }
          }
        }

        // however this is fine!
        await dir.exists();
        await file.exists();
        await link.exists();

        try {
          await link.delete();
          fail('should fail');
        } on FileSystemException catch (e) {
          _printErr(e);
          // Invalid argument for link

          if (isIoWindows(ctx)) {
            // FileSystemException: Cannot delete link, path = 'C:\devx\git\github.com\tekartik\fs_shim.dart\test_out\io\link\createdirectory_or_file\dir_or_file' (OS Error: Le fichier ou rÃ©pertoire nâ€™est pas un point dâ€™analyse., errno = 4390)
            try {
              expect(e.status, FileSystemException.statusInvalidArgument);
            } catch (te) {
              // [5] FileSystemException: Cannot create link to target 'target', path = 'C:\opt\devx\git\github.com\tekartik\fs_shim.dart\fs\.dart_tool\fs_shim\test\io\link\createdirectory_or_file\dir_or_file' (OS Error: Access is denied.
              //, errno = 5) [FileSystemExceptionImpl]
              expect(e.status, FileSystemException.statusAccessError);
            }
          } else {
            // [20] FileSystemException: Deletion failed, path = '/media/ssd/devx/hg/dart-pkg/lib/fs_shim/test_out/io/file/createdirectory_or_file/dir_or_file' (OS Error: Not a directory, errno = 20)
            // [20] FileSystemException: Deletion failed, path = '/file/createdirectory_or_file/dir_or_file' (OS Error: Not a directory, errno = 20)
            expect(e.status, FileSystemException.statusIsADirectory);
            /*
            if (isIo(ctx)) {
              // linux/android/mac
              expect(e.status, FileSystemException.statusInvalidArgument);
            } else {
              // mac, idb
              expect(e.status, FileSystemException.statusIsADirectory);
            }
            */
          }
        }

        await dir.delete();

        await dir.create();
        try {
          await link.create('target');
          fail('should fail');
        } on FileSystemException catch (e) {
          _printErr(e);
          if (isIoWindows(ctx)) {
            try {
              // [17] FileSystemException: Cannot create link to target '\??\C:\devx\git\github.com\tekartik\fs_shim.dart\test_out\io\link\createdirectory_or_file\target', path = 'C:\devx\git\github.com\tekartik\fs_shim.dart\test_out\io\link\createdirectory_or_file\dir_or_file' (OS Error: Impossible de crÃ©er un fichier dÃ©jÃ  existant., errno = 183)
              expect(e.status, FileSystemException.statusAlreadyExists);
            } catch (te) {
              // [5] FileSystemException: Cannot create link to target 'target', path = 'C:\opt\devx\git\github.com\tekartik\fs_shim.dart\fs\.dart_tool\fs_shim\test\io\link\createdirectory_or_file\dir_or_file' (OS Error: Access is denied.
              //, errno = 5) [FileSystemExceptionImpl]
              expect(e.status, FileSystemException.statusAccessError);
            }
          } else {
            // [21] FileSystemException: Cannot create file, path = '/media/ssd/devx/hg/dart-pkg/lib/fs_shim/test_out/io/file/createdirectory_or_file/dir_or_file' (OS Error: Is a directory, errno = 21)
            // [21] FileSystemException: Creation failed, path = '/file/createdirectory_or_file/dir_or_file' (OS Error: Is a directory, errno = 21)
            expect(e.status, FileSystemException.statusAlreadyExists);
          }
        }

        try {
          await link.delete();
          fail('should fail');
        } on FileSystemException catch (e) {
          _printErr(e);
          if (isIoWindows(ctx)) {
            expect(e.status, FileSystemException.statusInvalidArgument);
          } else {
            expect(e.status, FileSystemException.statusIsADirectory);
          }
          /*
          if (isIo(ctx)) {
            // win, mac, linux
            expect(e.status, FileSystemException.statusInvalidArgument);
          } else {
            // idb
            expect(e.status, FileSystemException.statusIsADirectory);
          }
          */
        }

        // however this is fine!
        await dir.exists();
        await file.exists();
        await link.exists();
      });

      group('dir', () {
        int indexOf(List<FileSystemEntity> list, FileSystemEntity entity) {
          for (var i = 0; i < list.length; i++) {
            if (list[i].path == entity.path) {
              return i;
            }
          }
          return -1;
        }

        FileSystemEntity? getInList(
          List<FileSystemEntity> list,
          FileSystemEntity entity,
        ) {
          for (var i = 0; i < list.length; i++) {
            if (list[i].path == entity.path) {
              return list[i];
            }
          }
          return null;
        }

        test('list_with_links', () async {
          if (fs.supportsLink) {
            final top = await ctx.prepare();

            final dir = childDirectory(top, 'dir');
            final link = childLink(top, 'link');
            await link.create(dir.path);

            var list = await top.list(followLinks: false).toList();
            expect(list.length, 1);
            expect(indexOf(list, link), 0);
            expect(list[0], const TypeMatcher<Link>());

            list = await top.list(followLinks: true).toList();
            expect(list.length, 1);
            expect(indexOf(list, link), 0);
            expect(list[0], const TypeMatcher<Link>());

            await dir.create();

            list = await top.list().toList();
            expect(list.length, 2);
            if (isIoWindows(ctx)) {
              expect(getInList(list, link), const TypeMatcher<Link>());
            } else {
              expect(getInList(list, link), const TypeMatcher<Directory>());
            }

            expect(getInList(list, dir), const TypeMatcher<Directory>());

            list = await top.list(followLinks: false).toList();
            expect(list.length, 2);
            expect(getInList(list, link), const TypeMatcher<Link>());
            expect(getInList(list, dir), const TypeMatcher<Directory>());

            list = await top.list(followLinks: true).toList();
            expect(list.length, 2);
            if (isIoWindows(ctx)) {
              expect(getInList(list, link), const TypeMatcher<Link>());
            } else {
              expect(getInList(list, link), const TypeMatcher<Directory>());
            }
            expect(getInList(list, dir), const TypeMatcher<Directory>());
          }
        });

        test('list_link', () async {
          if (fs.supportsLink) {
            List<FileSystemEntity> list;
            final top = await ctx.prepare();

            final dir = childDirectory(top, 'dir');
            final subFile = childFile(dir, 'subFile');
            final subDir = childDirectory(dir, 'subDir');
            final subLink = childLink(dir, 'subLink');

            final link = childLink(top, 'link');

            // target
            final linkSubFile = childFile(asDirectory(link), 'subFile');
            final linkSubDir = childFile(asDirectory(link), 'subDir');
            final linkSubLink = childFile(asDirectory(link), 'subLink');

            final linkDir = asDirectory(link);
            await link.create(dir.path);

            try {
              await linkDir.list().toList();
              fail('should fail');
            } on FileSystemException catch (e) {
              expect(e.status, FileSystemException.statusNotFound);
            }

            await dir.create();

            try {
              list = await linkDir.list(followLinks: false).toList();
              expect(list, isEmpty);
              expect(isIoWindows(ctx), isFalse);
            } on FileSystemException catch (e) {
              // fail only on windows
              expect(isIoWindows(ctx), isTrue);
              expect(e.status, FileSystemException.statusNotFound);
            }

            try {
              list = await linkDir.list(followLinks: true).toList();
              expect(list, isEmpty);
              expect(isIoWindows(ctx), isFalse);
            } on FileSystemException catch (e) {
              // fail only on windows
              expect(isIoWindows(ctx), isTrue);
              expect(e.status, FileSystemException.statusNotFound);
            }

            await subFile.create();
            await subLink.create(subDir.path);
            await subDir.create();

            try {
              list = await linkDir.list(followLinks: true).toList();
              expect(list.length, 3);
              expect(getInList(list, linkSubFile), const TypeMatcher<File>());
              expect(
                getInList(list, linkSubDir),
                const TypeMatcher<Directory>(),
              );
              expect(
                getInList(list, linkSubLink),
                const TypeMatcher<Directory>(),
              );
              expect(isIoWindows(ctx), isFalse);
            } on FileSystemException catch (e) {
              // fail only on windows
              expect(isIoWindows(ctx), isTrue);
              expect(e.status, FileSystemException.statusNotFound);
            }
            try {
              list = await linkDir.list(followLinks: false).toList();
              expect(list.length, 3);
              expect(getInList(list, linkSubFile), const TypeMatcher<File>());
              expect(
                getInList(list, linkSubDir),
                const TypeMatcher<Directory>(),
              );
              expect(getInList(list, linkSubLink), const TypeMatcher<Link>());
              expect(isIoWindows(ctx), isFalse);
            } on FileSystemException catch (e) {
              // fail only on windows
              expect(isIoWindows(ctx), isTrue);
              expect(e.status, FileSystemException.statusNotFound);
            }
          }
        });

        test('listdirectory_link_recursive', () async {
          if (fs.supportsLink) {
            List<FileSystemEntity> list;
            final top = await ctx.prepare();

            // file in target
            final target = childDirectory(top, 'target');
            final subFile = childFile(target, 'subFile');

            // link in dir
            final dir = childDirectory(top, 'dir');
            final link = childLink(dir, 'link');

            final linkSubFile = childFile(asDirectory(link), 'subFile');

            await subFile.create(recursive: true);
            await link.create(target.path, recursive: true);

            list = await dir.list(followLinks: true, recursive: true).toList();
            expect(list.length, 2);
            expect(getInList(list, link), const TypeMatcher<Directory>());
            expect(getInList(list, linkSubFile), const TypeMatcher<File>());

            list = await dir.list(followLinks: false, recursive: true).toList();
            expect(list.length, 1);
            expect(getInList(list, link), const TypeMatcher<Link>());

            // not recursive
            list = await dir.list(followLinks: true).toList();
            expect(list.length, 1);
            expect(getInList(list, link), const TypeMatcher<Directory>());

            list = await dir.list(followLinks: false).toList();
            expect(list.length, 1);
            expect(getInList(list, link), const TypeMatcher<Link>());
          }
        });
      });
      test('create relative', () async {
        final dirPath = fs.path.join(
          '.',
          '.dart_tool',
          'tekartik_fs_test',
          'test',
          'create_relative',
        );

        // Create a top level directory
        // fs.directory('/dir');
        final dir = fs.directory(dirPath);
        // print('dir: $dir');
        // delete its content
        if (await dir.exists()) {
          await dir.delete(recursive: true);
        }

        // and a file in it
        // fs.file(join(dir.path, "file"));
        final file = fs.file(fs.path.join(dir.path, 'file'));

        // create a file
        await file.create(recursive: true);
        await file.writeAsString('Hello world!');

        // read a file
        // use a file link if supported
        if (fs.supportsFileLink) {
          var link = fs.link(fs.path.join(dir.path, 'link'));
          await link.create('file');

          expect(await link.target(), 'file');
          expect(await fs.file(link.path).readAsString(), 'Hello world!');

          var linkFile = fs.file(link.path);
          expect(await linkFile.readAsString(), 'Hello world!');

          // list dir content
          expect(
            (await dir
                  .list(recursive: true, followLinks: true)
                  .map((event) => fs.path.basename(event.path))
                  .toList())
              ..sort(),
            ['file', 'link'],
          );
        }
      });
      test('example', () async {
        // debugIdbShowLogs = devWarning(true);
        final top = await ctx.prepare();

        var p = fs.path;
        var topPath = top.path;
        // Create a top level directory
        final dir = fs.directory(fs.path.join(topPath, 'dir'));

        // delete its content
        if (await dir.exists()) {
          await dir.delete(recursive: true);
        }
        // Create it
        // await dir.create(recursive: true);

        // and a file in it
        final file = fs.file(p.join(dir.path, 'file'));

        // create a file
        await file.create(recursive: true);
        await file.writeAsString('Hello world!');

        // read a file
        // print('file: $file');
        // print('content: ${await file.readAsString()}');

        // use a file link if supported
        if (fs.supportsFileLink) {
          final link = fs.link(p.join(dir.path, 'link'));
          await link.create(file.path);

          // print('link: $link target ${await link.target()}');
          // print('content: ${await fs.file(link.path).readAsString()}');
        }

        // list dir content
        // print('Listing dir: $dir');
        // ignore: unused_local_variable
        for (var fse
            in await dir.list(recursive: true, followLinks: true).toList()) {
          // print('  found: $fse');
        }
      });
    });
  }
}
