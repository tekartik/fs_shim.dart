// Copyright (c) 2015, <your name>. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library;

import 'package:dev_test/test.dart';

import 'test_common.dart';

void main() {
  group('default', () {
    defineFileSystemEntityParentTests(memoryFileSystemTestContext);
  });
}

// To deprecate
void defineTests(FileSystemTestContext ctx) {
  defineFileSystemEntityParentTests(ctx);
}

void defineFileSystemEntityParentTests(FileSystemTestContext ctx) {
  var fs = ctx.fs;
  var p = fs.path;

  final rootDir = ctx.baseDir.directory('file_system_entity_parent');
  final rootDirPath = rootDir.path;

  void parentGroup(FileSystemEntityParent parent) {
    test('api', () {
      // ignore: unnecessary_statements
      parent.directoryWith;
      // ignore: unnecessary_statements
      parent.directory;
      // ignore: unnecessary_statements
      parent.file;
    });
  }

  group('FileSystemEntityParent', () {
    parentGroup(rootDir);
    parentGroup(fs);

    test('fs', () {
      expect(fs.directory('test').path, 'test');
      expect(fs.directoryWith(path: 'test').path, 'test');
      expect(fs.file('test').path, 'test');
    });
    test('directory', () {
      expect(rootDir.fs.name, fs.name);
      // ignore: omit_local_variable_types
      File testFile = rootDir.file('test_file');
      // ignore: omit_local_variable_types
      Directory testDir = rootDir.directory('test_dir');
      // ignore: omit_local_variable_types
      Directory testDirWith = rootDir.directoryWith(path: 'with_test_dir');
      // ignore: omit_local_variable_types
      Directory testDirWithNull = rootDir.directoryWith();
      var testDirWithDot = rootDir.directoryWith(path: '.');
      expect(testFile.path, p.join(rootDirPath, 'test_file'));
      expect(testDir.path, p.join(rootDirPath, 'test_dir'));
      expect(testDirWith.path, p.join(rootDirPath, 'with_test_dir'));
      expect(testDirWithNull.path, rootDirPath);
      expect(testDirWithDot.path, rootDirPath);
      expect(testDirWithDot, same(testDirWithDot));
      expect(testDirWithNull, same(testDirWithNull));

      var dirRef1 = rootDir.directory('with_ref');
      var dirRef2 = rootDir.directory('with_ref');
      expect(dirRef1.path, dirRef2.path);
      expect(dirRef1.directoryWith(), same(dirRef1));
      expect(dirRef1.directoryWith(path: '.'), same(dirRef1));
      expect(dirRef1.directoryWith(), isNot(same(dirRef2)));
      expect(dirRef1.directoryWith(path: '.'), isNot(same(dirRef2)));
    });
  });
}
