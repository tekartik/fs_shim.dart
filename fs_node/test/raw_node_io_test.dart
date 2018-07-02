@TestOn("node")
// Copyright (c) 2015, Alexandre Roux. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.
library fs_shim.raw_node_io_test;

import 'package:path/path.dart';
import 'package:test/test.dart';
import 'package:node_io/node_io.dart';

void main() {
  group('raw_node_io', () {
    test('api', () async {
      var path = join(".dart_tool", "tekartik_fs_node", "raw_node_io_api");
      var directory = new Directory(path);
      directory = await directory.create(recursive: true);
      FileSystemEntity entity = await directory.delete();
      expect(entity, const TypeMatcher<Directory>());
    }, skip: true);
  });
}
