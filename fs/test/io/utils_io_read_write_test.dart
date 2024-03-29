@TestOn('vm')
library fs_shim.test.utils_entity_tests;

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

    test('write_read_sub', () async {
      final file = File(join(outPath, 'sub', 'file'));
      await writeString(file, 'test');
      expect(await readString(file), 'test');

      await writeString(file, 'test2');
      expect(await readString(file), 'test2');
    });
  });
}
