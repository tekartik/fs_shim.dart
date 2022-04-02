@TestOn('vm')
import 'dart:io';

import 'package:fs_shim/utils/path.dart';
import 'package:test/test.dart';

void main() {
  group('utils_path_io', () {
    test('dir', () async {
      if (Platform.isLinux || Platform.isMacOS) {
        expect(toNativePath('test'), 'test');
        expect(toNativePath('test/sub'), 'test/sub');
        expect(toNativePath('test\\sub'), 'test/sub');
      } else if (Platform.isWindows) {
        expect(toNativePath('test'), 'test');
        expect(toNativePath('test/sub'), 'test\\sub');
        expect(toNativePath('test\\sub'), 'test\\sub');
      }
    });
  });
}
