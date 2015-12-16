library fs_shim.test.utils_copy_tests;

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
  group('path', () {
    test('posixPath', () async {
      expect(posixPath('a\\b'), 'a/b');
          });

    test('contextPath', () async {
      expect(contextPath('a\\b'), join('a', 'b'));
    });

    test('contextIsWindows', () async {
      if (contextIsWindows) {
        expect(separator, '\\');
      } else {
        expect(separator, '/');
      }
      expect(posix.style, isNot(windows.style));
      expect(url.style, isNot(windows.style));
    });
  });
}
