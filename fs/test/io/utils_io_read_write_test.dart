@TestOn('vm')
library;

import 'dart:io';

import 'package:fs_shim/utils/io/read_write.dart';
import 'package:path/path.dart';
import 'package:test/test.dart';

import '../test_common_io.dart' show ioFileSystemTestContext;

String get outPath => ioFileSystemTestContext.outPath;

void main() {
  group('utils_read_write', () {
    test('write_read', () async {
      final file = File(join(outPath, 'file'));
      await writeString(file, 'test');
      expect(await readString(file), 'test');

      await writeString(file, 'test2');
      expect(await readString(file), 'test2');
    });

    test('write_read_lines', () async {
      final file = File(join(outPath, 'file'));
      await writeLines(file, []);
      expect(await readLines(file), <String>[]);
      await writeLines(file, ['test1', 'test2']);
      expect(await readLines(file), ['test1', 'test2']);
      if (Platform.isWindows) {
        expect(await readString(file), 'test1\r\ntest2\r\n');
      } else {
        expect(await readString(file), 'test1\ntest2\n');
      }
    });

    test('write_read_sub', () async {
      final file = File(join(outPath, 'sub', 'file'));
      await writeString(file, 'test');
      expect(await readString(file), 'test');

      await writeString(file, 'test2');
      expect(await readString(file), 'test2');
    });
  });
}
