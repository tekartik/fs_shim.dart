@TestOn('vm')
// Copyright (c) 2015, Alexandre Roux. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library fs_shim.fs_src_idb_io_test;

import 'package:fs_shim/fs_idb.dart';
import 'package:fs_shim/src/idb/idb_file_system.dart';
import 'package:idb_shim/idb_io.dart';
import 'package:path/path.dart';
import 'package:tekartik_fs_test/fs_test.dart';
import 'package:tekartik_fs_test/test_common.dart';

var testOutTopPath = join('.dart_tool', 'tekartik_fs_idb_io', 'test');
final _idbFactory = getIdbFactorySembastIo(testOutTopPath);

FileSystem newIdbIoFileSystem([String? name]) {
  // IdbFactoryLogger.debugMaxLogCount = devWarning(256);
  return newFileSystemIdb(
      // devWarning(getIdbFactoryLogger(getIdbFactorySembastIo(testOutTopPath))),
      _idbFactory,
      name);
}

var _index = 0;

class FileSystemTestContextIdbIo extends FileSystemTestContextIdbWithOptions {
  @override
  late final IdbFileSystem fs = () {
    var fs = newIdbIoFileSystem('test_idb_io_${++_index}');

    fs = fs.withIdbOptions(options: options);
    return fs as FileSystemIdb;
  }();

  FileSystemTestContextIdbIo({FileSystemIdbOptions? options})
      : super(options: options ?? FileSystemIdbOptions.pageDefault);
}

void main() {
  // debugIdbShowLogs = devWarning(true);
  group('idb_io', () {
    for (var options in [
      FileSystemIdbOptions.pageDefault,
      FileSystemIdbOptions.noPage,
      const FileSystemIdbOptions(pageSize: 2),
      const FileSystemIdbOptions(pageSize: 1024)
    ]) {
      group('pageSize ${options.pageSize}', () {
        defineFsTests(FileSystemTestContextIdbIo(options: options));
      });
    }
  });
}
