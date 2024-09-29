@TestOn('browser')
library;

import 'package:fs_shim/fs_browser.dart';
import 'package:tekartik_fs_test/fs_perf_test.dart';
import 'package:tekartik_fs_test/test_common.dart';
import 'package:test/test.dart';

var _options = [
  FileSystemIdbOptions.noPage,
  const FileSystemIdbOptions(pageSize: 64 * 1024),
  FileSystemIdbOptions.pageDefault,
  const FileSystemIdbOptions(pageSize: 1024),
  const FileSystemIdbOptions(pageSize: 128)
];
var _fsList = _options.map((e) => getFileSystemWeb(options: e)).toList();

void main() {
  group('perf_browser', () {
    for (var fs in _fsList) {
      fsPerfTestGroup(fs);
    }
  });
  Future<void> writeResult() async {
    var resultText = fsPerfMarkdownResult();
    // ignore: avoid_print
    print(resultText);
  }

  tearDownAll(() async {
    await writeResult();
  });
}
