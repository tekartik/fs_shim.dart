// Copyright (c) 2015, <your name>. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.
library fs_shim.fs_none_test;

import 'package:fs_shim/fs_none.dart';
import 'package:fs_shim/src/common/fs_mixin.dart';
import 'package:test/test.dart';

class MyFileSystem extends Object with FileSystemMixin {}

class MyFile extends MyFileSystemEntity with FileMixin {}

abstract class MyFileSystemEntity extends Object with FileSystemEntityMixin {}

class MyDirectory extends MyFileSystemEntity with DirectoryNone {}

void main() {
  group('none', () {
    test('entities', () {
      MyFileSystem();
      MyFile();
      MyDirectory();
    });
  });
}
