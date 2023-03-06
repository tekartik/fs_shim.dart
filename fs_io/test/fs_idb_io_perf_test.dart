@TestOn('vm')
library fs_shim_browser.fs_idb_sqflite_perf_test;

import 'dart:io' as io;

import 'package:fs_shim/fs_idb.dart';
import 'package:idb_shim/idb_io.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tekartik_fs_test/fs_perf_test.dart';
import 'package:tekartik_fs_test/test_common.dart';

import 'fs_idb_sqflite_perf_test.dart';

var _fsList = idbOptions.map((e) => newFileSystemIdb(getIdbFactorySembastIo(
        p.join('.dart_tool', 'tekartik_fs_test', 'perf_idb_io')))
    .withIdbOptions(options: e));

void main() {
  sqfliteFfiInit();
  group('perf_idb_sqflite', () {
    for (var fs in _fsList) {
      fsPerfTestGroup(fs, params: [
        FsPerfParam(100, 2),
        FsPerfParam(100, 1024),
        FsPerfParam(20, 64 * 1024),
      ]);
    }
  });
  Future<void> writeResult() async {
    var file = io.File(
        p.join('.dart_tool', 'tekartik_fs_test', 'perf', 'perf_idb_io.md'));
    await file.parent.create(recursive: true);
    var resultText = fsPerfMarkdownResult();
    print(resultText);
    await file.writeAsString(resultText);
  }

  tearDownAll(() async {
    await writeResult();
  });
}
