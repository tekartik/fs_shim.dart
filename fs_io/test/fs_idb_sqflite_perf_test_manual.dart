@TestOn('vm')
library fs_shim_browser.fs_idb_sqflite_perf_test;

import 'dart:io' as io;

import 'package:fs_shim/fs_idb.dart';
import 'package:idb_sqflite/idb_sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:process_run/stdio.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tekartik_fs_test/fs_perf_test.dart';
import 'package:tekartik_fs_test/test_common.dart';
import 'package:test/test.dart';

var idbOptions = [
  FileSystemIdbOptions.noPage,
  const FileSystemIdbOptions(pageSize: 64 * 1024),
  FileSystemIdbOptions.pageDefault,
  const FileSystemIdbOptions(pageSize: 1024),
  const FileSystemIdbOptions(pageSize: 128)
];
var _fsList = idbOptions.map((e) =>
    newFileSystemIdb(getIdbFactorySqflite(databaseFactoryFfiNoIsolate))
        .withIdbOptions(options: e));

void main() {
  sqfliteFfiInit();
  group('perf_idb_sqflite', () {
    for (var fs in _fsList) {
      fsPerfTestGroup(fs);
    }
  });
  Future<void> writeResult() async {
    var file = io.File(p.join(
        '.dart_tool', 'tekartik_fs_test', 'perf', 'perf_idb_sqflite.md'));
    await file.parent.create(recursive: true);
    var resultText = fsPerfMarkdownResult();
    stdout.writeln(resultText);
    await file.writeAsString(resultText);
  }

  tearDownAll(() async {
    await writeResult();
  });
}
