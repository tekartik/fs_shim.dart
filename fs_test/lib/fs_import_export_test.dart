// Copyright (c) 2015, <your name>. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library;

import 'package:dev_test/test.dart';
import 'package:fs_shim/fs_memory.dart';
import 'package:fs_shim/utils/import_export.dart';
import 'package:path/path.dart';
// ignore_for_file: unnecessary_import

import 'fs_shim_file_stat_test.dart';
import 'test_common.dart';

void main() {
  defineTests(memoryFileSystemTestContext);
}

Future<void> expectMatchesButDate(Directory dir1, Directory dir2) async {
  var p1 = dir1.fs.path;
  var p2 = dir2.fs.path;
  var stat1 = await dir1.stat();
  var stat2 = await dir2.stat();
  expect(stat1.type, stat2.type);
  if (stat1.type == FileSystemEntityType.notFound) {
    return;
  }
  var entities1 = List.of(await dir1.list(recursive: true).toList());
  entities1.sort((a, b) => a.path.compareTo(b.path));
  var entities2 = List.of(await dir2.list(recursive: true).toList());
  entities2.sort((a, b) => a.path.compareTo(b.path));
  var i = 0;
  for (; i < entities1.length; i++) {
    var entity1 = entities1[i];

    if (i >= entities2.length) {
      fail('missing $entity1 in $entities2');
    }
    var entity2 = entities2[i];

    var name1 = p1.relative(entity1.path, from: dir1.path);
    var name2 = p2.relative(entity2.path, from: dir2.path);
    expect(
      posix.normalize(name1),
      posix.normalize(name2),
      reason: '$name1 != $name2',
    );

    if (entity1 is Link) {
      expect(entity2 is Link, isTrue, reason: '$entity1 is Link, not $entity2');
    }
    if (entity1 is File) {
      expect(entity2 is File, isTrue, reason: '$entity1 is File, not $entity2');
      expect(
        await entity1.readAsBytes(),
        await (entity2 as File).readAsBytes(),
      );
    }
    if (entity1 is Directory) {
      expect(
        entity2 is Directory,
        isTrue,
        reason: '$entity1 is Directory, not $entity2',
      );
    }
  }
  if (i < entities2.length) {
    fail('missing ${entities2[i]} in $entities1');
  }
}

void defineImportExportTests(FileSystemTestContext ctx) {
  test('import_export', () async {
    final dir = await ctx.prepare();
    var src = dir.directory('src');
    var dst = dir.directory('dst');
    var dst2 = newFileSystemMemory().directory('dst2');

    await expectMatchesButDate(src, dst);
    await expectMatchesButDate(src, dst2);

    Future<void> exportImport() async {
      var export = await fsIdbExportLines(src.sandbox());
      await fsIdbImport(dst.sandbox(), export);
      await fsIdbImport(dst2.sandbox(), export);
    }

    await exportImport();
    await expectMatchesButDate(src, dst);
    await expectMatchesButDate(src, dst2);

    await src.create(recursive: true);

    Future<void> checkBeforeAndAfterImport() async {
      await expectLater(() => expectMatchesButDate(src, dst), throwsException);
      await expectLater(() => expectMatchesButDate(src, dst2), throwsException);

      await exportImport();
      await expectMatchesButDate(src, dst);
      await expectMatchesButDate(src, dst2);
    }

    await checkBeforeAndAfterImport();
    // Sub dir file1
    var file1 = src.file(src.fs.path.join('sub1', 'sub2', 'file1'));
    await file1.create(recursive: true);
    await file1.writeAsString('hello');

    await checkBeforeAndAfterImport();
  });
}
