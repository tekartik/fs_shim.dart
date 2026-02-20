@TestOn('vm')
library;

import 'dart:io';

import 'package:path/path.dart';
import 'package:test/test.dart';

/// Empty or create helper
extension DirectoryEmptyOrCreateExt on Directory {
  /// Ensure the directory is created and empty.
  Future<void> emptyOrCreate() async {
    if (await exists()) {
      try {
        await delete(recursive: true);
      } catch (_) {
        // ignore
      }
    }
    await create(recursive: true);
  }
}

void main() {
  var rawPath = join('.dart_tool', 'tekartik', 'fs_shim', 'raw_io');
  test('raw dir link', () async {
    var dir = Directory(join(rawPath, 'dir_link'));
    await dir.emptyOrCreate();
    var subDir = Directory(join(dir.path, 'sub1', 'dir'));
    await subDir.create(recursive: true);
    var subFile = File(join(subDir.path, 'file1'));
    await subFile.writeAsString('hello');
    var link = Link(join(dir.path, 'sub2', 'link'));
    await link.create(normalize(absolute(subDir.path)), recursive: true);
    expect(await Directory(link.path).list().toList(), hasLength(1));
    expect(await File(join(link.path, 'file1')).readAsString(), 'hello');
  }, skip: !Platform.isLinux);
}
