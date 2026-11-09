@TestOn('browser')
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:tekartik_fs_test_app/src/platform_helper.dart';

void main() {
  test('web file system per database name', () async {
    // The database name of the Web (IndexedDB) card was ignored: every name
    // gave the default fileSystemWeb (review of 2026-11-09).
    var fs1 = getWebFileSystem(name: 'fs_test_app_test_1');
    var fs2 = getWebFileSystem(name: 'fs_test_app_test_2');
    var file1 = fs1.file('/name.txt');
    var file2 = fs2.file('/name.txt');
    if (await file2.exists()) {
      await file2.delete();
    }
    await file1.writeAsString('1');
    expect(await file1.readAsString(), '1');
    expect(await file2.exists(), isFalse);
  });
}
