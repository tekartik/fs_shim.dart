// Copyright (c) 2015, <your name>. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library fs_shim.test.fs_shim_sanity_test;

import 'package:dev_test/test.dart';
// ignore_for_file: unnecessary_import
import 'package:fs_shim/fs.dart';

import 'test_common.dart';
//import 'package:path/path.dart' as p;

void main() {
  defineTests(memoryFileSystemTestContext);
}

void defineTests(FileSystemTestContext ctx) {
  var fs = ctx.fs;
  int indexOf(List<FileSystemEntity> list, FileSystemEntity entity) {
    for (var i = 0; i < list.length; i++) {
      if (list[i].path == entity.path) {
        return i;
      }
    }
    return -1;
  }

  group('sanity', () {
    test('test1', () async {
      final top = await ctx.prepare();

      final src = childDirectory(top, 'src');
      await src.create();
      final dst = childDirectory(top, 'dst');

      final file = childFile(src, 'file');
      await file.writeAsString('test', flush: true);

      if (fs.supportsFileLink) {
        final link = childLink(src, 'link');
        await link.create(file.path);
        expect(await fs.isLink(link.path), isTrue);
      }

      final copy = TopCopy(fsTopEntity(src), fsTopEntity(dst),
          options: CopyOptions(recursive: true));
      await copy.run();

      final dstFile = childFile(dst, 'file');
      expect(await dstFile.readAsString(), 'test');

      if (fs.supportsFileLink) {
        final dstLink = childFile(dst, 'link');
        expect(await dstLink.readAsString(), 'test');
        expect(await fs.isLink(dstLink.path), isFalse);
      }

      final list = <FileSystemEntity>[];
      await top.list(recursive: true).listen((FileSystemEntity fse) {
        list.add(fse);
      }).asFuture<void>();

      expect(indexOf(list, src), isNot(-1));
      expect(indexOf(list, dst), isNot(-1));
      expect(list.length, fs.supportsFileLink ? 6 : 4);
    });
  });
}
