library fs_shim.test.utils_part_tests;

import 'package:path/path.dart';
import 'package:test/test.dart';

import 'test_common.dart';

void main() {
  defineTests(memoryFileSystemTestContext);
}

late FileSystemTestContext _ctx;

FileSystem get fs => _ctx.fs;

void defineTests(FileSystemTestContext ctx) {
  _ctx = ctx;
  group('part', () {
    test('splitParts', () async {
      final top = await ctx.prepare();

      var parts = ctx.fs.path.split(top.path);
      expect(parts, contains('splitParts'));

      // always working
      // ignore: deprecated_member_use
      parts = splitParts(top.path);
      expect(parts, contains('splitParts'));

      // also always working (the implementation)
      parts = windows.split(top.path);
      expect(parts, contains('splitParts'));

      // ignore: deprecated_member_use
      if (!contextIsWindows) {
        parts = url.split(top.path);
        expect(parts, contains('splitParts'));

        parts = posix.split(top.path);
        expect(parts, contains('splitParts'));
      }
    });
  });
}
