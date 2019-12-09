library fs_shim.test.utils_entity_tests;

import 'package:fs_shim/fs.dart';
import 'package:fs_shim/utils/entity.dart';
import 'package:path/path.dart';

import '../test_common.dart';

void main() {
  defineTests(memoryFileSystemTestContext);
}

FileSystemTestContext _ctx;

FileSystem get fs => _ctx.fs;

void defineTests(FileSystemTestContext ctx) {
  _ctx = ctx;
  group('entity', () {
    test('as', () async {
      final fileSystemEntity = fs.link('fse');
      final link = asLink(fileSystemEntity);
      final file = asFile(fileSystemEntity);
      final directory = asDirectory(fileSystemEntity);
      expect(link.path, fileSystemEntity.path);
      expect(file.path, fileSystemEntity.path);
      expect(directory.path, fileSystemEntity.path);
    });

    test('child', () async {
      final top = fs.directory('top');
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
