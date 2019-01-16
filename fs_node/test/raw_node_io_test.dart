@TestOn("node")
// Copyright (c) 2015, Alexandre Roux. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.
library fs_shim.raw_node_io_test;

import 'dart:io' as vm_io;

import 'package:node_io/node_io.dart';
import 'package:path/path.dart';
import 'package:test/test.dart';

void main() {
  group('raw_node_io', () {
    test('api', () async {
      var path = join(".dart_tool", "tekartik_fs_node", "raw_node_io_api");
      var directory = Directory(path);
      directory = await directory.create(recursive: true);
      vm_io.FileSystemEntity entity = await directory.delete();
      expect(entity, const TypeMatcher<Directory>());
    }, skip: true);
  });
}
