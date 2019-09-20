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
  await copyAll(['multiplatform/fs_shim_link_test.dart']);
}
