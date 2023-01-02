library fs_shim.test.utils_path_tests;

import 'test_common.dart';

void main() {
  defineTests(memoryFileSystemTestContext);
}

void defineTests(FileSystemTestContext ctx) {
  var fs = ctx.fs;
  group('path', () {
    test('split', () async {
      expect(contextPathSplit(fs.path, '\\a/b\\c/d'),
          [ctx.fs.path.separator, 'a', 'b', 'c', 'd']);
    });
  });
}
