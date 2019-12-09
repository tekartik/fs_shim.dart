import 'dart:io';

import 'package:path/path.dart';

Future main() async {
  var src = '../fs/test';
  var dst = 'lib';

  Future copy(String file, {bool rootDir}) async {
    var dstFile =
        (rootDir ?? false) ? join(dst, file) : join(dst, basename(file));
    await Directory(dirname(dstFile)).create(recursive: true);
    await File(join(src, file)).copy(dstFile);
  }

  Future copyAll(List<String> files) async {
    for (var file in files) {
      print(file);
      await copy(file);
    }
  }

  /*
  var list = Directory(src)
      .listSync(recursive: true)
      .map((entity) => relative(entity.path, from: src))
      .where((path) =>
          split(path).first != 'web' &&
          FileSystemEntity.isFileSync(join(src, path)));

  //

  if (Directory(dst).existsSync()) {
    await Directory(dst).delete(recursive: true);
  }

  print(list);
  await copyAll([
    ...list,
  ]);
   */
  await copyAll([
    'multiplatform/fs_shim_link_test.dart',
    'multiplatform/fs_shim_dir_test.dart',
    'multiplatform/fs_shim_file_stat_test.dart',
    'multiplatform/fs_shim_file_system_exception_test.dart',
    'multiplatform/fs_shim_file_system_test.dart',
    'multiplatform/fs_shim_file_test.dart',
    'multiplatform/fs_shim_sanity_test.dart',
    'multiplatform/fs_test.dart',
    'multiplatform/utils_copy_test.dart',
    'multiplatform/utils_entity_test.dart',
    'multiplatform/utils_part_test.dart',
    'multiplatform/utils_path_test.dart',
    'multiplatform/utils_read_write_test.dart',
    'multiplatform/utils_test.dart',
  ]);
}
