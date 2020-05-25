@TestOn('vm')
import 'dart:io';

import 'package:path/path.dart';
import 'package:test/test.dart';

Future testSameFileContent(String path1, String path2) async {
  // print(path1);
  expect(await File(path1).readAsString(), await File(path2).readAsString(),
      reason: '$path1 differs');
}

void main() {
  group('fs_test', () {
    test('fs/fs_test same files', () async {
      // Somehow we have either...
      // fs_test
      // or
      // fs_test/test
      var dir = Directory.current.path;
      // print(dir);
      if (basename(dir) == 'test') {
        dir = dirname(dir);
      }
      final fs = join(dir, '..', 'fs', 'test', 'multiplatform');
      final fsTest = join(dir, 'lib');
      for (var file in [
        'fs_shim_link_test.dart',
        'fs_shim_dir_test.dart',
        'fs_shim_file_stat_test.dart',
        'fs_shim_file_system_exception_test.dart',
        'fs_shim_file_system_test.dart',
        'fs_shim_file_test.dart',
        'fs_shim_sanity_test.dart',
        'fs_test.dart',
        'utils_copy_test.dart',
        'utils_entity_test.dart',
        'utils_part_test.dart',
        'utils_path_test.dart',
        'utils_read_write_test.dart',
        'utils_test.dart',
      ]) {
        await testSameFileContent(join(fs, file), join(fsTest, file));
      }
    });
  });
}
