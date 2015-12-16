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

void main() {
  FileSystem fs = ioFileSystemContext.fs;
  group('io', () {
    test('windows', () {
      expect(isIoWindows(ioFileSystemContext), io.Platform.isWindows);
    });
    test('name', () {
      expect(ioFileSystemContext.fs.name, 'io');
    });
    test('equals', () {
      // Files cannot be compared!
      expect(new io.File("test"), isNot(new io.File("test")));
    });
    test('type', () async {
      expect(await ioFileSystemContext.fs.type(testScriptPath),
          FileSystemEntityType.FILE);
      expect(await ioFileSystemContext.fs.type(dirname(testScriptPath)),
          FileSystemEntityType.DIRECTORY);
    });
    test('test_path', () async {
      expect(ioFileSystemContext.outTopPath,
          join(dirname(dirname(testScriptPath)), "test_out"));
      expect(ioFileSystemContext.outPath,
          join(ioFileSystemContext.outTopPath, joinAll(testDescriptions)));
    });

    solo_group('conversion', () {
      test('file', () {
        io.File ioFile = new io.File('dir');
        File file = wrapIoFile(ioFile);
        expect(unwrapIoFile(file), ioFile);
      });
      test('dir', () {
        io.Directory ioDirectory = new io.Directory('dir');
        Directory dir = wrapIoDirectory(ioDirectory);
        expect(unwrapIoDirectory(dir), ioDirectory);
      });
      test('link', () {
        io.Link ioLink = new io.Link('dir');
        Link link = wrapIoLink(ioLink);
        expect(unwrapIoLink(link), ioLink);
      });

      test('oserror', () {
        io.OSError ioOSError = new io.OSError();
        //OSError osError = wrapIoOSError(ioOSError);
      });

      test('filestat', () async {
        io.FileStat ioFileStat = await io.Directory.current.stat();
        FileStat fileStat = wrapIoFileStat(ioFileStat);
        expect(unwrapIoFileStat(fileStat), ioFileStat);
      });
    });

    group('raw', () {
      test('dir', () {
        Directory dir = new Directory("dir");
        File file = new File("file");
        expect(file.fs, fs);
        expect(dir.fs, fs);
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
            FileSystemEntityType.DIRECTORY);
        expect(
            await FileSystemEntity.type(Directory.current.path,
                followLinks: false),
            FileSystemEntityType.DIRECTORY);
      });
    });

    // All tests
    defineTests(ioFileSystemContext);
  });
}
