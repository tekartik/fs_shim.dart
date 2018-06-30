// Copyright (c) 2015, <your name>. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.
library fs_shim.fs_none_test;

import 'package:fs_shim/fs_none.dart';
import 'package:test/test.dart';

class MyFileSystem extends Object with FileSystemNone {}

class MyFile extends MyFileSystemEntity with FileNone {}

abstract class MyFileSystemEntity extends Object with FileSystemEntityNone {}

class MyDirectory extends MyFileSystemEntity with DirectoryNone {}

main() {
  group('none', () {
    test('entities', () {
      new MyFileSystem();
      new MyFile();
      new MyDirectory();
    });
  });
}
