library fs_shim.test.utils_copy_tests;

import 'package:fs_shim/utils/copy.dart';
import 'package:path/path.dart';
import 'package:fs_shim/fs.dart';
import 'test_common.dart';

main() {
  defineTests(memoryFileSystemTestContext);
}

FileSystemTestContext _ctx;
FileSystem get fs => _ctx.fs;

void defineTests(FileSystemTestContext ctx) {
  _ctx = ctx;
  group('part', () {
    test('splitParts', () async {
      Directory top = await ctx.prepare();

      List<String> parts = ctx.fs.pathContext.split(top.path);
      expect(parts, contains("splitParts"));

      // always working
      parts = splitParts(top.path);
      expect(parts, contains("splitParts"));

      // also always working (the implementation)
      parts = windows.split(top.path);
      expect(parts, contains("splitParts"));

      if (!contextIsWindows) {
        parts = url.split(top.path);
        expect(parts, contains("splitParts"));

        parts = posix.split(top.path);
        expect(parts, contains("splitParts"));
      }
    });
  });
}
