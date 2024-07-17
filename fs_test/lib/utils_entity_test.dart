library fs_shim.test.utils_entity_tests;

import 'package:dev_test/test.dart';

import 'test_common.dart';

void main() {
  defineTests(memoryFileSystemTestContext);
}

void defineTests(FileSystemTestContext ctx) {
  var fs = ctx.fs;
  group('entity', () {
    test('as', () async {
      if (fs.supportsLink) {
        final fileSystemEntity = fs.link('fse');
        final link = asLink(fileSystemEntity);
        final file = asFile(fileSystemEntity);
        final directory = asDirectory(fileSystemEntity);
        expect(link.path, fileSystemEntity.path);
        expect(file.path, fileSystemEntity.path);
        expect(directory.path, fileSystemEntity.path);
      }
    });

    test('child', () async {
      final top = fs.directory('top');
      final file = childFile(top, 'child');
      final directory = childDirectory(top, 'child');
      expect(fs.path.basename(file.path), 'child');
      expect(fs.path.basename(directory.path), 'child');
      expect(file.parent.path, top.path);
      expect(directory.parent.path, top.path);
      if (fs.supportsLink) {
        final link = childLink(top, 'child');
        expect(fs.path.basename(link.path), 'child');
        expect(link.parent.path, top.path);
      }
    });
  });
}
