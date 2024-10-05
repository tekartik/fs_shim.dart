@TestOn('vm')
library;

import 'dart:io';

import 'package:fs_shim/utils/io/read_write.dart';
import 'package:path/path.dart';
import 'package:test/test.dart';

import '../test_common_io.dart' show ioFileSystemTestContext;

String get outPath => ioFileSystemTestContext.outPath;

void main() {
  group('file_lines_io', () {
    test('linesTo/FromIoString', () {
      expect(linesToIoString([]), '');
      expect(linesFromIoString(''), <String>[]);
      expect(linesFromIoString(linesToIoString(['a', 'b'])), ['a', 'b']);
    });
    if (Platform.isWindows) {
      test('stringToIoString', () {
        expect(stringToIoString('a\nb'), 'a\r\nb\r\n');
        expect(stringToIoString('a\r\nb'), 'a\r\nb\r\n');
      });
      test('linesToIoString', () {
        expect(linesToIoString(['a', 'b']), 'a\r\nb\r\n');
      });
    } else {
      test('stringToIoString', () {
        expect(stringToIoString('a\nb'), 'a\nb\n');
        expect(stringToIoString('a\r\nb'), 'a\nb\n');
      });
      test('linesToIoString', () {
        expect(linesToIoString(['a', 'b']), 'a\nb\n');
      });
    }
  });
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
