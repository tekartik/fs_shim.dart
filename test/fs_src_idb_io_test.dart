@TestOn("vm")
// Copyright (c) 2015, Alexandre Roux. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library fs_shim.fs_src_idb_io_test;

import 'package:fs_shim/fs.dart';
import 'package:fs_shim/fs_idb.dart';
import 'package:fs_shim/src/idb/idb_file_system.dart';
import 'package:idb_shim/idb_io.dart';
import 'package:dev_test/test.dart';
import 'fs_src_idb_test.dart';
import 'test_common_io.dart';
import 'test_common.dart';
import 'package:path/path.dart';
import 'dart:async';
import 'package:platform_context/context.dart';

FileSystem newIdbIoFileSystem([String name]) =>
    newIdbFileSystem(getIdbSembastIoFactory(testOutTopPath), name);

class IdbIoFileSystemTestContext extends IdbFileSystemTestContext {
  final PlatformContext platform = null;
  IdbFileSystem fs = newIdbIoFileSystem();
  IdbIoFileSystemTestContext();

  @override
  Future<Directory> prepare() {
    fs = newIdbIoFileSystem(join(super.outPath, 'lfs.db'));
    return super.prepare();
  }
}

IdbIoFileSystemTestContext idbIoFileSystemContext =
    new IdbIoFileSystemTestContext();

void main() {
  group('idb_io', () {
    // All tests
    defineTests(idbIoFileSystemContext);
  });
}
