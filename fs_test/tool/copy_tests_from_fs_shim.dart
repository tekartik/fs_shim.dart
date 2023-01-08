import 'dart:io';

import 'package:path/path.dart';

Future main() async {
  var src = '../fs/test/multiplatform';
  var dst = 'lib';
  await App(src: src, dst: dst).run();
}

class App {
  final String src;
  final String dst;

  App({required this.src, required this.dst});

  Future _copy(String file) async {
    var dstFile = join(dst, file);
    await Directory(dirname(dstFile)).create(recursive: true);
    await File(join(src, file)).copy(dstFile);
  }

  Future _copyAll(List<String> files) async {
    for (var file in files) {
      print(file);
      await _copy(file);
    }
  }

  Future<void> run() async {
    await _copyAll([
      'fs_shim_link_test.dart',
      'fs_shim_dir_test.dart',
      'fs_shim_file_stat_test.dart',
      'fs_shim_file_system_exception_test.dart',
      'fs_shim_file_system_test.dart',
      'fs_shim_file_test.dart',
      'fs_shim_sanity_test.dart',
      'fs_test.dart',
      'fs_test_common.dart',
      'fs_shim_test.dart',
      'fs_shim_random_access_file_test.dart',
      'utils_copy_test.dart',
      'utils_entity_test.dart',
      'utils_path_test.dart',
      'utils_read_write_test.dart',
      'utils_test.dart',
    ]);
  }
}
