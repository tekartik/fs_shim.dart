@TestOn('vm')
// Copyright (c) 2015, Alexandre Roux. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library fs_shim.fs_src_idb_io_test;

import 'package:fs_shim/fs_idb.dart';
import 'package:fs_shim/src/idb/idb_file_system.dart';
import 'package:idb_shim/idb_client.dart' as idb;
import 'package:idb_shim/idb_io.dart';

import '../multiplatform/fs_idb_format_test.dart';
import '../multiplatform/fs_idb_format_v1_test.dart';
import '../multiplatform/fs_idb_test.dart';
import '../multiplatform/platform.dart';
import '../test_common.dart';
import '../test_common_io.dart';

idb.IdbFactory get idbFactory => getIdbFactorySembastIo(testOutTopPath);

FileSystem newIdbIoFileSystem([String? name]) =>
    newFileSystemIdb(getIdbFactorySembastIo(testOutTopPath), name);

class IdbIoFileSystemTestContext extends IdbFileSystemTestContext {
  @override
  final PlatformContext? platform = null;
  @override
  IdbFileSystem fs = newIdbIoFileSystem() as IdbFileSystem;

  IdbIoFileSystemTestContext();

  @override
  Future<Directory> prepare() {
    fs = newIdbIoFileSystem(fs.path.join(super.outPath, 'fs.db'))
        as IdbFileSystem;
    return super.prepare();
  }
}

IdbIoFileSystemTestContext idbIoFileSystemContext =
    IdbIoFileSystemTestContext();

void main() {
  group('idb_io', () {
    // All tests
    fsIdbFormatGroup(idbFactory);
    fsIdbFormatV1Group(idbFactory);

    defineTests(idbIoFileSystemContext);
  });
}
