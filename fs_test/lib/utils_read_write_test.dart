library fs_shim.test.utils_read_write_test;

import 'package:dev_test/test.dart';

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

    test('write_read_lines', () async {
      final top = await ctx.prepare();
      final file = fs.file(fs.path.join(top.path, 'file'));
      await writeLines(file, []);
      expect(await readLines(file), <String>[]);
      await writeLines(file, ['test1', 'test2']);
      expect(await readLines(file), ['test1', 'test2']);
      await writeLines(file, ['test1', 'test2'], useCrLf: true);
      expect(await readString(file), 'test1\r\ntest2\r\n');
      await writeLines(file, ['test1', 'test2'], useCrLf: false);
      expect(await readString(file), 'test1\ntest2\n');
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
