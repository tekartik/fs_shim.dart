import 'package:fs_shim/fs_idb.dart';
import 'package:test/test.dart';

import 'fs_test_common.dart';

void main() {
  group('context', () {
    test('Memory', () {
      var fs = MemoryFileSystemTestContextWithOptions(
        options: const FileSystemIdbOptions(pageSize: 2),
      );
      expect(fs.options.pageSize, 2);
    });
  });
}
