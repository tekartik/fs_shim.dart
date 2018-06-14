@TestOn("vm")
// Copyright (c) 2015, Alexandre Roux. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library fs_shim.fs_io_test;

import 'package:dev_test/test.dart';
import 'fs_test.dart';
import 'dart:io' as io;
import 'package:fs_shim/fs_io.dart';
import 'test_common_io.dart';
import 'test_common.dart';
import 'package:path/path.dart';
import 'package:dart2_constant/io.dart' as constant;

void main() {
  FileSystem fs = ioFileSystemTestContext.fs;
  group('io', () {
    test('windows', () {
      expect(isIoWindows(ioFileSystemTestContext), io.Platform.isWindows);
    });
    test('name', () {
      expect(ioFileSystemTestContext.fs.name, 'io');
    });
    test('equals', () {
      // Files cannot be compared!
      expect(new io.File("test"), isNot(new io.File("test")));
      expect(new io.Directory("test"), isNot(new io.Directory("test")));
    });
    test('type', () async {
      expect(await ioFileSystemTestContext.fs.type(testScriptPath),
          FileSystemEntityType.file);
      expect(await ioFileSystemTestContext.fs.type(dirname(testScriptPath)),
          FileSystemEntityType.directory);
    });
    test('test_path', () async {
      expect(
          ioFileSystemTestContext.outTopPath,
          join(dirname(dirname(testScriptPath)), ".dart_tool", "fs_shim",
              "test_out"));
      expect(ioFileSystemTestContext.outPath,
          join(ioFileSystemTestContext.outTopPath, joinAll(testDescriptions)));
    });

    group('conversion', () {
      test('file', () {
        io.File ioFile = new io.File('file');
        File file = wrapIoFile(ioFile);
        expect(unwrapIoFile(file), ioFile);
      });
      test('dir', () {
        io.Directory ioDirectory = new io.Directory('dir');
        Directory dir = wrapIoDirectory(ioDirectory);
        expect(unwrapIoDirectory(dir), ioDirectory);
      });
      test('link', () {
        io.Link ioLink = new io.Link('link');
        Link link = wrapIoLink(ioLink);
        expect(unwrapIoLink(link), ioLink);
      });

      test('filesystementity', () {
        io.FileSystemEntity ioFse = new io.Link('link');
        FileSystemEntity fse = wrapIoLink(ioFse as io.Link);
        expect(ioFse.path, fse.path);

        ioFse = new io.Directory('dir');
        fse = wrapIoDirectory(ioFse as io.Directory);

        ioFse = new io.File('file');
        fse = wrapIoFile(ioFse as io.File);
      });

      test('oserror', () {
        io.OSError ioOSError = new io.OSError();
        OSError osError = wrapIoOSError(ioOSError);
        expect(unwrapIoOSError(osError), ioOSError);
      });

      test('filestat', () async {
        io.FileStat ioFileStat = await io.Directory.current.stat();
        FileStat fileStat = wrapIoFileStat(ioFileStat);
        expect(unwrapIoFileStat(fileStat), ioFileStat);
      });

      test('filesystemexception', () {
        io.FileSystemException ioFileSystemException =
            new io.FileSystemException();
        FileSystemException fileSystemException =
            wrapIoFileSystemException(ioFileSystemException);
        expect(unwrapIoFileSystemException(fileSystemException),
            ioFileSystemException);
      });

      test('filemode', () async {
        io.FileMode ioFileMode = constant.FileMode.read;
        FileMode fileMode = wrapIoFileMode(ioFileMode);
        expect(unwrapIoFileMode(fileMode), ioFileMode);

        ioFileMode = constant.FileMode.write;
        fileMode = wrapIoFileMode(ioFileMode);
        expect(unwrapIoFileMode(fileMode), ioFileMode);

        ioFileMode = constant.FileMode.append;
        fileMode = wrapIoFileMode(ioFileMode);
        expect(unwrapIoFileMode(fileMode), ioFileMode);
      });

      test('fileentitytype', () async {
        io.FileSystemEntityType ioFset = constant.FileSystemEntityType.notFound;
        FileSystemEntityType fset = wrapIoFileSystemEntityType(ioFset);
        expect(unwrapIoFileSystemEntityType(fset), ioFset);

        ioFset = constant.FileSystemEntityType.file;
        fset = wrapIoFileSystemEntityType(ioFset);
        expect(unwrapIoFileSystemEntityType(fset), ioFset);

        ioFset = constant.FileSystemEntityType.directory;
        fset = wrapIoFileSystemEntityType(ioFset);
        expect(unwrapIoFileSystemEntityType(fset), ioFset);

        ioFset = constant.FileSystemEntityType.link;
        fset = wrapIoFileSystemEntityType(ioFset);
        expect(unwrapIoFileSystemEntityType(fset), ioFset);
      });
    });

    group('raw', () {
      test('dir', () async {
        Directory dir = new Directory("dir");
        File file = new File("file");
        expect(file.fs, fs);
        expect(dir.fs, fs);

        try {
          dir = new Directory(join(Directory.current.path,
              "never_exist_such_a_dummy_dir_for_fs_shim_testing"));
          await dir.list().toList();
        } catch (_) {}
      });

      test('filestat', () async {
        io.FileStat ioFileStat = await io.Directory.current.stat();
        FileStat fileStat = await Directory.current.stat();
        expect(fileStat.size, ioFileStat.size);
      });

      test('current', () {
        expect(Directory.current.path, io.Directory.current.path);
      });

      test('FileSystemEntity', () async {
        expect(await FileSystemEntity.isLink(Directory.current.path), isFalse);
        expect(
            await FileSystemEntity.isDirectory(Directory.current.path), isTrue);
        expect(await FileSystemEntity.isFile(Directory.current.path), isFalse);
        expect(
            await FileSystemEntity.type(Directory.current.path,
                followLinks: true),
            FileSystemEntityType.directory);
        expect(
            await FileSystemEntity.type(Directory.current.path,
                followLinks: false),
            FileSystemEntityType.directory);
      });
    });

    // All tests
    defineTests(ioFileSystemTestContext);
  });
}
