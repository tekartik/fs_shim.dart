@TestOn('vm')
// Copyright (c) 2015, Alexandre Roux. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.
library fs_shim.raw_io_test;

import 'dart:io';

import 'package:path/path.dart';
import 'package:test/test.dart';

void main() {
  group('raw_io', () {
    test('api', () async {
      var path = join('.dart_tool', 'tekartik_fs_node', 'raw_io_api');
      var directory = Directory(path);
      directory = await directory.create(recursive: true);
      final entity = await directory.delete();
      expect(entity, const TypeMatcher<Directory>());
    }, skip: true);
  });
}
