library;

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

    test('streamToFile', () async {
      final top = await ctx.prepare();
      final file = fs.file(fs.path.join(top.path, 'file'));
      // Multiple chunks
      expect(
        await streamToFile(
          Stream<List<int>>.fromIterable(['te'.codeUnits, 'st'.codeUnits]),
          file,
        ),
        file,
      );
      expect(await readString(file), 'test');

      // Overwrite (truncate)
      await streamToFile(Stream.value('a'.codeUnits), file);
      expect(await readString(file), 'a');

      // Empty stream
      await streamToFile(const Stream<List<int>>.empty(), file);
      expect(await file.exists(), isTrue);
      expect(await readString(file), '');
    });

    test('streamToFile_sub', () async {
      final top = await ctx.prepare();
      // Parent directory does not exist
      final file = fs.file(fs.path.join(top.path, 'sub', 'file'));
      await streamToFile(Stream.value('test'.codeUnits), file);
      expect(await readString(file), 'test');

      // Extension
      final file2 = fs.file(fs.path.join(top.path, 'sub2', 'sub', 'file'));
      expect(await file2.writeStream(Stream.value('test2'.codeUnits)), file2);
      expect(await readString(file2), 'test2');
    });

    test('Directory.emptyOrCreate', () async {
      final top = await ctx.prepare();
      var dir = fs.directory(fs.path.join(top.path, 'dir'));
      expect(await dir.exists(), isFalse);
      await dir.emptyOrCreate();
      expect(await dir.exists(), isTrue);
      // test 2 level depth
      dir = fs.directory(fs.path.join(top.path, 'sub', 'dir'));
      expect(await dir.exists(), isFalse);
      await dir.emptyOrCreate();
      expect(await dir.exists(), isTrue);
    });
  });
}
