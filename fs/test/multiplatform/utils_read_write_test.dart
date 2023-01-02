library fs_shim.test.utils_read_write_test;

import 'test_common.dart';

void main() {
  defineTests(memoryFileSystemTestContext);
}

void defineTests(FileSystemTestContext ctx) {
  var fs = ctx.fs;
  group('utils_read_write', () {
    test('write_read', () async {
      final top = await ctx.prepare();
      final file = fs.file(fs.path.join(top.path, 'file'));
      await writeString(file, 'test');
      expect(await readString(file), 'test');

      await writeString(file, 'test2');
      expect(await readString(file), 'test2');
    });

    test('write_read_sub', () async {
      final top = await ctx.prepare();
      final file = fs.file(fs.path.join(top.path, 'sub', 'file'));
      await writeString(file, 'test');
      expect(await readString(file), 'test');

      await writeString(file, 'test2');
      expect(await readString(file), 'test2');
    });
  });
}
