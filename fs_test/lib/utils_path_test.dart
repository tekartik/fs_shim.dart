library fs_shim.test.utils_path_tests;

import 'test_common.dart';

void main() {
  defineTests(memoryFileSystemTestContext);
}

late FileSystemTestContext _ctx;

FileSystem get fs => _ctx.fs;

void defineTests(FileSystemTestContext ctx) {
  _ctx = ctx;
  group('path', () {
    test('split', () async {
      expect(contextPathSplit(ctx.fs.path, '\\a/b\\c/d'),
          [ctx.fs.path.separator, 'a', 'b', 'c', 'd']);
    });
  });
}
