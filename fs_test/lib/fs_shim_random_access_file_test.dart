// Copyright (c) 2015, <your name>. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library fs_shim.test.fs_shim_file_test;

// ignore_for_file: unnecessary_import
import 'package:fs_shim/fs.dart';

import 'test_common.dart';

void main() {
  defineTests(memoryFileSystemTestContext);
}

void defineTests(FileSystemTestContext ctx) {
  var fs = ctx.fs;
  //idbSupportsV2Format = devWarning(true);
  //debugIdbShowLogs = devWarning(true);
  group('random_access_file', () {
    test('simple read/write', () async {
      final directory = await ctx.prepare();
      var filePath = fs.path.join(directory.path, 'position');
      final file = fs.file(filePath);
      var randomAccessFile = await file.open(mode: FileMode.write);
      try {
        expect(await randomAccessFile.position(), 0);
        expect(await randomAccessFile.length(), 0);
        await randomAccessFile.writeString('test');
        expect(await randomAccessFile.position(), 4);
        expect(await randomAccessFile.length(), 4);

        await randomAccessFile.setPosition(0);
        expect(utf8.decode(await randomAccessFile.read(4)), 'test');
        expect(await randomAccessFile.readByte(), -1);
        await randomAccessFile.setPosition(3);
        expect(await randomAccessFile.readByte(), 116);
        expect(await randomAccessFile.readByte(), -1);
        await randomAccessFile.writeByte(115);
        expect(await randomAccessFile.length(), 5);
        await randomAccessFile.setPosition(0);
        expect(utf8.decode(await randomAccessFile.read(20)), 'tests');

        expect(await randomAccessFile.position(), 5);
        randomAccessFile = await randomAccessFile.truncate(4);
        expect(await randomAccessFile.length(), 4);
      } finally {
        await randomAccessFile.close();
      }
    });

    test('truncate', () async {
      final directory = await ctx.prepare();
      var filePath = fs.path.join(directory.path, 'truncatee');
      final file = fs.file(filePath);
      var randomAccessFile = await file.open(mode: FileMode.write);
      try {
        await randomAccessFile.writeString('test');
        await randomAccessFile.writeByte(115);
        expect(await randomAccessFile.length(), 5);
        await randomAccessFile.setPosition(0);
        expect(utf8.decode(await randomAccessFile.read(20)), 'tests');

        expect(await randomAccessFile.position(), 5);
        randomAccessFile = await randomAccessFile.truncate(4);
        expect(await randomAccessFile.length(), 4);

        // on linux and idb
        var positionKept = await randomAccessFile.position() == 5;
        if (positionKept) {
          expect(await randomAccessFile.position(), 5);
        } else {
          expect(await randomAccessFile.position(), 4);
        }
        await randomAccessFile.writeByte(115);
        if (positionKept) {
          expect(await randomAccessFile.length(), 6);
        } else {
          expect(await randomAccessFile.position(), 5);
        }
        await randomAccessFile.setPosition(0);
        if (positionKept) {
          expect(utf8.decode(await randomAccessFile.read(20)), 'test\x00s');
        } else {
          expect(utf8.decode(await randomAccessFile.read(20)), 'tests');
        }
        randomAccessFile = await randomAccessFile.truncate(10);
        expect(await randomAccessFile.length(), 10);
        await randomAccessFile.setPosition(2);
        if (positionKept) {
          expect(utf8.decode(await randomAccessFile.read(20)),
              'st\x00s\x00\x00\x00\x00');
        } else {
          expect(utf8.decode(await randomAccessFile.read(20)),
              'sts\x00\x00\x00\x00\x00');
        }
        //randomAccessFile = await randomAccessFile.truncate(20);
      } finally {
        await randomAccessFile.close();
      }
    });
    test('complex read/write', () async {
      final directory = await ctx.prepare();
      var filePath = fs.path.join(directory.path, 'position');
      final file = fs.file(filePath);
      var randomAccessFile = await file.open(mode: FileMode.write);
      try {
        expect(await randomAccessFile.position(), 0);
        await randomAccessFile.writeString('test');
        expect(await randomAccessFile.position(), 4);
        for (var byte in utf8.encode('other')) {
          await randomAccessFile.writeByte(byte);
        }
        expect(await randomAccessFile.position(), 9);
        await randomAccessFile.setPosition(3);
        var replacement = utf8.encode('replacement');
        await randomAccessFile.writeFrom(replacement, 2, 6);
        expect(await randomAccessFile.position(), 7);

        await randomAccessFile.setPosition(1);
        expect(await randomAccessFile.readByte(), 101); // 'e'
        expect(await randomAccessFile.position(), 2);

        var buffer = List<int>.filled(10, 0);
        expect(await randomAccessFile.readInto(buffer, 1, 6), 5);
        expect(buffer, [0, 115, 112, 108, 97, 99, 0, 0, 0, 0]);
      } finally {
        await randomAccessFile.close();
      }
    });
  }, skip: !fs.supportsRandomAccess);
}
