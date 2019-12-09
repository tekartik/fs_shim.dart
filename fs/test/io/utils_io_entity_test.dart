@TestOn('vm')
library fs_shim.test.utils_entity_tests;

import 'dart:io';

import 'package:dev_test/test.dart';
import 'package:fs_shim/utils/io/entity.dart';
import 'package:path/path.dart';

import '../test_common_io.dart' show ioFileSystemTestContext;

String get outPath => ioFileSystemTestContext.outPath;

void main() {
  group('entity', () {
    test('as', () async {
      final fileSystemEntity = Link(join(outPath, 'fse'));
      final link = asLink(fileSystemEntity);
      final file = asFile(fileSystemEntity);
      final directory = asDirectory(fileSystemEntity);
      expect(link.path, fileSystemEntity.path);
      expect(file.path, fileSystemEntity.path);
      expect(directory.path, fileSystemEntity.path);
    });

    test('child', () async {
      final top = Directory(join(outPath, 'top'));
      final link = childLink(top, 'child');
      final file = childFile(top, 'child');
      final directory = childDirectory(top, 'child');
      expect(basename(link.path), 'child');
      expect(basename(file.path), 'child');
      expect(basename(directory.path), 'child');
      expect(link.parent.path, top.path);
      expect(file.parent.path, top.path);
      expect(directory.parent.path, top.path);
    });
  });
}
