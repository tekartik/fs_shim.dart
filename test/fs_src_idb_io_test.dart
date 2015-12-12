@TestOn("vm")
// Copyright (c) 2015, Alexandre Roux. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library fs_shim.fs_src_idb_io_test;

import 'package:fs_shim/fs.dart';
import 'package:fs_shim/src/idb/idb_fs.dart';
import 'package:idb_shim/idb_io.dart';
import 'package:dev_test/test.dart';
import 'fs_src_idb_test.dart';
import 'test_common_io.dart';
import 'test_common.dart';
import 'package:path/path.dart';
import 'dart:async';
import 'package:platform_context/context.dart';

class IdbIoFileSystem extends IdbFileSystem {
  IdbIoFileSystem([String name])
      : super(getIdbSembastIoFactory(testOutTopPath), name);
}

class IdbIoFileSystemTestContext extends IdbFileSystemTestContext {
  final PlatformContext platform = null;
  IdbIoFileSystem fs = new IdbIoFileSystem();
  IdbIoFileSystemTestContext();

  @override
  Future<Directory> prepare() {
    fs = new IdbIoFileSystem(join(super.outPath, 'lfs.db'));
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
