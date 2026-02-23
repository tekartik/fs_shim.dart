@TestOn('vm')
// Copyright (c) 2015, Alexandre Roux. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.
library;

import 'dart:io' as io;

import 'package:fs_shim/fs.dart';
import 'package:fs_shim/fs_io.dart';
import 'package:path/path.dart' as path_prefix;
import 'package:path/path.dart';

import '../test_common.dart';
import '../test_common_io.dart';

void main() {
  FileSystem fs = ioFileSystemTestContext.fs;
  final p = fs.path;
  group('io', () {
    test('supportRandomAccess', () {
      expect(fs.supportsRandomAccess, true);
    });
    test('supportsLink', () {
      expect(fs.supportsLink, true);
    });
    test('supportsFileLink', () {
      expect(fs.supportsFileLink, !io.Platform.isWindows);
    });
    test('windows config', () {
      expect(isIoWindows(ioFileSystemTestContext), io.Platform.isWindows);
      if (isIoWindows(ioFileSystemTestContext)) {
        //fs.path.rootPrefix(path)
      }
    });
    test('linux config', () async {
      expect(isIoLinux(ioFileSystemTestContext), io.Platform.isLinux);
      if (isIoLinux(ioFileSystemTestContext)) {
        expect(fs.path.rootPrefix(fs.path.absolute(fs.path.separator)), '/');
      }
    });
    test('windows.absolute/normalize', () {
      var ctx = path_prefix.windows;

      var path = ctx.join('C:\\', 'folder', 'file.txt');
      var absolutePath = ctx.absolute(path);
      expect(absolutePath, 'C:\\folder\\file.txt');
      path = ctx.join('C:\\', '..', 'folder', 'file.txt');
      absolutePath = ctx.absolute(path);
      expect(absolutePath, 'C:\\..\\folder\\file.txt');
      path = ctx.join('\\', '..', 'folder', 'file.txt');
      absolutePath = ctx.absolute(path);
      expect(absolutePath, '\\..\\folder\\file.txt');

      var normalizedPath = ctx.normalize('C:\\..\\file.txt');
      expect(normalizedPath, 'C:\\file.txt');
      normalizedPath = ctx.normalize('C:\\..');
      expect(normalizedPath, 'C:\\');

      normalizedPath = ctx.normalize('\\..\\file.txt');
      expect(normalizedPath, '\\file.txt');
      normalizedPath = ctx.normalize('\\..\\..\\file.txt');
      expect(normalizedPath, '\\file.txt');
    });
    test('posix.absolute/normalize', () {
      var ctx = path_prefix.posix;

      var path = ctx.join('/', 'folder', 'file.txt');
      var absolutePath = ctx.absolute(path);
      expect(absolutePath, '/folder/file.txt');
      path = ctx.join('/', '..', 'folder', 'file.txt');
      absolutePath = ctx.absolute(path);
      expect(absolutePath, '/../folder/file.txt');
      path = ctx.join('/', '..', 'folder', 'file.txt');
      absolutePath = ctx.absolute(path);
      expect(absolutePath, '/../folder/file.txt');

      var normalizedPath = ctx.normalize('/../file.txt');
      expect(normalizedPath, '/file.txt');
      normalizedPath = ctx.normalize('/../file.txt');
      expect(normalizedPath, '/file.txt');
      normalizedPath = ctx.normalize('/../../file.txt');
      expect(normalizedPath, '/file.txt');

      normalizedPath = ctx.normalize('/sub/root/./test.txt');
      expect(normalizedPath, '/sub/root/test.txt');
    });
    test('linux run', () async {
      if (isIoLinux(ioFileSystemTestContext)) {
        expect(p.rootPrefix(p.absolute(p.separator)), '/');
        expect(fs.absolutePath('/'), '/');
        expect(
          fs.absolutePath('\\'),
          fs.normalizePath(join(fs.currentDirectory.path, '\\')),
        ); // !!
        expect(fs.absolutePath('.'), fs.currentDirectory.path);
        expect(p.absolute('.'), startsWith('/'));
        expect(p.isAbsolute('./.'), isFalse);
        // Try to write above root
        var path = '/../test.txt';
        var absolutePath = p.absolute(path);
        expect(absolutePath, '/../test.txt');
        var file = fs.file(absolutePath);
        expect(await file.exists(), isFalse);
        try {
          await file.create(recursive: true);
        } on FileSystemException catch (e) {
          // error [5] PathAccessException: Cannot create file,
          // path = '/../test.txt' (OS Error: Permission denied, errno = 13)

          /// To adapt for CI maybe
          expect(e.status, FileSystemException.statusAccessError);
          expect(e.osError?.errorCode, 13);
        }
        var dir = fs.directory('/..');
        expect(await dir.exists(), isTrue); // ! Arg!
        await dir.create(recursive: true);
      }
    });
    test('windows run', () async {
      var rootPrefix = fs.path.rootPrefix(fs.path.absolute(fs.path.separator));

      expect(fs.absolutePath('.'), fs.currentDirectory.path);
      expect(fs.absolutePath('/'), '\\');
      expect(fs.absolutePath('\\'), '\\');
      expect(fs.absolutePath('C:\\'), 'C:\\');
      // On windows rootPrefix is something 'C:\\'
      expect(rootPrefix, endsWith(r'\'));

      // fs_shim.dart\fs\.
      expect(fs.path.absolute('.'), endsWith(r'\.'));
      expect(fs.path.isAbsolute('./.'), isFalse);
      expect(fs.path.isAbsolute(r'.\.'), isFalse);
      // Try to write above root
      var path = '/../test.txt';
      var absolutePath = fs.path.absolute(path);
      expect(absolutePath, '$rootPrefix../test.txt');
      var file = fs.file(absolutePath);
      expect(await file.exists(), isFalse);
      try {
        await file.create(recursive: true);
      } on FileSystemException catch (e) {
        // linux:
        // error [5] PathAccessException: Cannot create file,
        // path = '/../test.txt' (OS Error: Permission denied, errno = 13)
        //
        // windows:
        // e: [5] PathAccessException: Cannot create file,
        // path = 'C:\../test.txt' (OS Error: Access is denied, errno = 5)

        /// To adapt for CI maybe
        expect(e.status, FileSystemException.statusAccessError);
        expect(e.osError?.errorCode, 5);
      }
      var dir = fs.directory('/..');
      expect(await dir.exists(), isTrue); // ! Arg!
      await dir.create(recursive: true);
    }, skip: !isIoWindows(ioFileSystemTestContext));
    test('name', () {
      expect(fs.name, 'io');
    });
    test('equals', () {
      // Files cannot be compared!
      expect(io.File('test'), isNot(io.File('test')));
      expect(io.Directory('test'), isNot(io.Directory('test')));
    });
    test('type', () async {
      expect(
        await ioFileSystemTestContext.fs.type(
          fs.path.join('test', 'io', 'fs_io_test.dart'),
        ),
        FileSystemEntityType.file,
      );
      expect(await fs.type('test'), FileSystemEntityType.directory);
    });
    test('test_path', () async {
      expect(
        ioFileSystemTestContext.outTopPath,
        join('.dart_tool', 'fs_shim', 'test'),
      );
      expect(
        dirname(ioFileSystemTestContext.outPath),
        dirname(
          fs.path.join(
            ioFileSystemTestContext.outTopPath!,
            joinAll(testDescriptions),
          ),
        ),
      );
    });

    group('conversion', () {
      test('file', () {
        final ioFile = io.File('file');
        final file = wrapIoFile(ioFile);
        expect(unwrapIoFile(file), ioFile);
      });
      test('dir', () {
        final ioDirectory = io.Directory('dir');
        final dir = wrapIoDirectory(ioDirectory);
        expect(unwrapIoDirectory(dir), ioDirectory);
      });
      test('link', () {
        final ioLink = io.Link('link');
        final link = wrapIoLink(ioLink);
        expect(unwrapIoLink(link), ioLink);
      });

      test('filesystementity', () {
        io.FileSystemEntity ioFse = io.Link('link');
        FileSystemEntity fse = wrapIoLink(ioFse as io.Link);
        expect(ioFse.path, fse.path);

        ioFse = io.Directory('dir');
        fse = wrapIoDirectory(ioFse as io.Directory);

        ioFse = io.File('file');
        fse = wrapIoFile(ioFse as io.File);
      });

      test('oserror', () {
        const ioOSError = io.OSError();
        final osError = wrapIoOSError(ioOSError);
        expect(unwrapIoOSError(osError), ioOSError);
      });

      test('filestat', () async {
        final ioFileStat = io.Directory.current.statSync();
        final fileStat = wrapIoFileStat(ioFileStat);
        expect(unwrapIoFileStat(fileStat), ioFileStat);
      });

      test('filesystemexception', () {
        const ioFileSystemException = io.FileSystemException();
        final fileSystemException = wrapIoFileSystemException(
          ioFileSystemException,
        );
        expect(
          unwrapIoFileSystemException(fileSystemException),
          ioFileSystemException,
        );
      });

      test('filemode', () async {
        var ioFileMode = io.FileMode.read;
        var fileMode = wrapIoFileMode(ioFileMode);
        expect(unwrapIoFileMode(fileMode), ioFileMode);

        ioFileMode = io.FileMode.write;
        fileMode = wrapIoFileMode(ioFileMode);
        expect(unwrapIoFileMode(fileMode), ioFileMode);

        ioFileMode = io.FileMode.append;
        fileMode = wrapIoFileMode(ioFileMode);
        expect(unwrapIoFileMode(fileMode), ioFileMode);
      });

      test('fileentitytype', () async {
        var ioFset = io.FileSystemEntityType.notFound;
        var fset = wrapIoFileSystemEntityType(ioFset);
        expect(unwrapIoFileSystemEntityType(fset), ioFset);

        ioFset = io.FileSystemEntityType.file;
        fset = wrapIoFileSystemEntityType(ioFset);
        expect(unwrapIoFileSystemEntityType(fset), ioFset);

        ioFset = io.FileSystemEntityType.directory;
        fset = wrapIoFileSystemEntityType(ioFset);
        expect(unwrapIoFileSystemEntityType(fset), ioFset);

        ioFset = io.FileSystemEntityType.link;
        fset = wrapIoFileSystemEntityType(ioFset);
        expect(unwrapIoFileSystemEntityType(fset), ioFset);
      });
    });

    group('raw', () {
      test('dir', () async {
        var dir = Directory('dir');
        final file = File('file');
        expect(file.fs, fs);
        expect(dir.fs, fs);

        try {
          dir = Directory(
            fs.path.join(
              Directory.current.path,
              'never_exist_such_a_dummy_dir_for_fs_shim_testing',
            ),
          );
          await dir.list().toList();
        } catch (_) {}
      });

      test('filestat', () async {
        final ioFileStat = io.Directory.current.statSync();
        final fileStat = await Directory.current.stat();
        expect(fileStat.size, ioFileStat.size);
      });

      test('current', () {
        expect(Directory.current.path, io.Directory.current.path);
      });

      test('FileSystemEntity', () async {
        expect(
          await
          // ignore: avoid_slow_async_io
          FileSystemEntity.isLink(Directory.current.path),
          isFalse,
        );
        expect(
          await
          // ignore: avoid_slow_async_io
          FileSystemEntity.isDirectory(Directory.current.path),
          isTrue,
        );
        expect(
          await
          // ignore: avoid_slow_async_io
          FileSystemEntity.isFile(Directory.current.path),
          isFalse,
        );
        expect(
          await
          // ignore: avoid_slow_async_io
          FileSystemEntity.type(Directory.current.path, followLinks: true),
          FileSystemEntityType.directory,
        );
        expect(
          await
          // ignore: avoid_slow_async_io
          FileSystemEntity.type(Directory.current.path, followLinks: false),
          FileSystemEntityType.directory,
        );
      });
    });
    test('sandbox', () async {
      var sandbox = fs.sandbox() as FsShimSandboxedFileSystem;
      expect(sandbox.rootDirectory, fs.currentDirectory);
    });
    test('absolutePath', () async {
      var path = fs.absolutePath('.');
      expect(path, fs.currentDirectory.path);
    });
  });
}
