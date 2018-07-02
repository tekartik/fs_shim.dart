library fs_shim.test.utils_read_write_test;

import 'package:path/path.dart';
import 'package:fs_shim/fs.dart';
import 'test_common.dart';

void main() {
  defineTests(memoryFileSystemTestContext);
}

FileSystemTestContext _ctx;
FileSystem get fs => _ctx.fs;

void defineTests(FileSystemTestContext ctx) {
  _ctx = ctx;
  group('utils_read_write', () {
    test('write_read', () async {
      Directory top = await ctx.prepare();
      File file = fs.newFile(join(top.path, 'file'));
      await writeString(file, "test");
      expect(await readString(file), "test");

      await writeString(file, "test2");
      expect(await readString(file), "test2");
    });

    test('write_read_sub', () async {
      Directory top = await ctx.prepare();
      File file = fs.newFile(fs.path.join(top.path, 'sub', 'file'));
      await writeString(file, "test");
      expect(await readString(file), "test");

      await writeString(file, "test2");
      expect(await readString(file), "test2");
    });
  });
}
