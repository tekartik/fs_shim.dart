@TestOn('vm')
// Copyright (c) 2015, Alexandre Roux. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library fs_shim.fs_src_idb_io_test;

import 'package:fs_shim/fs_idb.dart';
import 'package:fs_shim/src/idb/idb_file_system.dart';
import 'package:idb_shim/idb_io.dart';

import '../multiplatform/fs_idb_format_test.dart';
import '../multiplatform/fs_idb_format_v1_test.dart';
import '../multiplatform/fs_idb_test.dart';
import '../multiplatform/fs_src_idb_file_system_storage_test.dart';
import '../test_common.dart';
import '../test_common_io.dart';

final _idbFactory = getIdbFactorySembastIo(testOutTopPath);

FileSystem newIdbIoFileSystem([String? name]) {
  // IdbFactoryLogger.debugMaxLogCount = devWarning(256);
  return newFileSystemIdb(
      // devWarning(getIdbFactoryLogger(getIdbFactorySembastIo(testOutTopPath))),
      getIdbFactorySembastIo(testOutTopPath),
      name);
}

class IdbIoFileSystemTestContext extends IdbFileSystemTestContext {
  @override
  late final IdbFileSystem rawFsIdb = () {
    var fs = newIdbIoFileSystem('test') as IdbFileSystem;
    return fs;
  }();

  IdbIoFileSystemTestContext();
}

IdbIoFileSystemTestContext _idbIoFileSystemContext =
    IdbIoFileSystemTestContext();

void main() {
  group('idb_io', () {
    // All tests
    fsIdbMultiFormatGroup(_idbFactory);
    fsIdbFormatGroup(_idbFactory);
    fsIdbFormatV1Group(_idbFactory);
    defineIdbTypesFileSystemStorageTests(_idbIoFileSystemContext);
    defineIdbTests(_idbIoFileSystemContext);
  });
}
