// Copyright (c) 2018, Alexandre Roux. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'package:fs_shim/fs_memory.dart';
import 'package:test/test.dart';

void main() {
  group('memory', () {
    defineTests(newFileSystemMemory());
  });
}

void defineTests(FileSystem fs) {
  group('currentDir', () {
    test('writeAsString', () async {
      // direct file write, no preparation
      await fs.file('file.tmp').writeAsString('context');
    }, skip: false);
  });
}
