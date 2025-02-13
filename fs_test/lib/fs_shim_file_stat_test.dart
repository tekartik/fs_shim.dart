// Copyright (c) 2015, <your name>. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library;

import 'package:dev_test/test.dart';
// ignore_for_file: unnecessary_import
import 'package:fs_shim/fs.dart';

import 'test_common.dart';

var allowNullNotFoundDate = false;

/// Since 2.8, Not Found date time for access, modified, created is never null
/// but set to 0 epoch
void expectNotFoundDateTime(DateTime dateTime) {
  try {
    expect(dateTime.millisecondsSinceEpoch, 0);
  } catch (e) {
    // Allow null
    if (allowNullNotFoundDate) {
      expect(dateTime, null);
    } else {
      rethrow;
    }
  }
}

void main() {
  defineTests(memoryFileSystemTestContext);
}

void defineTests(FileSystemTestContext ctx) {
  var fs = ctx.fs;

  group('file_stat', () {
    test('stat', () async {
      final top = await ctx.prepare();

      final file = fs.file(fs.path.join(top.path, 'file'));

      await file.writeAsString('test', flush: true);
      final stat = await file.stat();
      expect(stat.type, FileSystemEntityType.file);
      expect(stat.size, 4);
      print(stat.modified);
      expect(
        stat.modified.difference(DateTime.now()).inDays.abs(),
        lessThan(1),
      );
    });
  });
}
