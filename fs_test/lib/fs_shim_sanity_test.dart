// Copyright (c) 2015, <your name>. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library fs_shim.test.fs_shim_sanity_test;

import 'package:fs_shim/fs.dart';
import 'test_common.dart';
//import 'package:path/path.dart';

main() {
  defineTests(memoryFileSystemTestContext);
}

FileSystemTestContext _ctx;
FileSystem get fs => _ctx.fs;

void defineTests(FileSystemTestContext ctx) {
  _ctx = ctx;

  int indexOf(List<FileSystemEntity> list, FileSystemEntity entity) {
    for (int i = 0; i < list.length; i++) {
      if (list[i].path == entity.path) {
        return i;
      }
    }
    return -1;
  }

  group('sanity', () {
    test('test1', () async {
      Directory top = await ctx.prepare();

      Directory src = childDirectory(top, 'src');
      await src.create();
      Directory dst = childDirectory(top, 'dst');

      File file = childFile(src, "file");
      await file.writeAsString("test", flush: true);

      if (fs.supportsFileLink) {
        Link link = childLink(src, 'link');
        await link.create(file.path);
        expect(await fs.isLink(link.path), isTrue);
      }

      TopCopy copy = new TopCopy(fsTopEntity(src), fsTopEntity(dst),
          options: new CopyOptions(recursive: true));
      await copy.run();

      File dstFile = childFile(dst, "file");
      expect(await dstFile.readAsString(), 'test');

      if (fs.supportsFileLink) {
        File dstLink = childFile(dst, "link");
        expect(await dstLink.readAsString(), 'test');
        expect(await fs.isLink(dstLink.path), isFalse);
      }

      List<FileSystemEntity> list = [];
      await top.list(recursive: true).listen((FileSystemEntity fse) {
        list.add(fse);
      }).asFuture();

      expect(indexOf(list, src), isNot(-1));
      expect(indexOf(list, dst), isNot(-1));
      expect(list.length, fs.supportsFileLink ? 6 : 4);
    });
  });
}
