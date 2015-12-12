@TestOn("browser")
// Copyright (c) 2015, Alexandre Roux. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library fs_shim.fs_browser_test;

import 'package:fs_shim/fs.dart';
import 'package:fs_shim/src/idb/fs_idb.dart';
import 'package:idb_shim/idb_browser.dart';
import 'package:dev_test/test.dart';
import 'fs_src_idb_test.dart';
import 'test_common.dart';
import 'package:path/path.dart';
import 'dart:async';
import 'package:platform_context/context.dart';
import 'package:platform_context/context_browser.dart';

class IdbBrowserFileSystem extends IdbFileSystem {
  IdbBrowserFileSystem([String name]) : super(idbBrowserFactory, name);
}

class IdbBrowserFileSystemTestContext extends IdbFileSystemTestContext {
  final PlatformContext platform = browserPlatformContext;
  IdbBrowserFileSystem fs = new IdbBrowserFileSystem();
  IdbBrowserFileSystemTestContext();

  @override
  Future<Directory> prepare() async {
    fs = new IdbBrowserFileSystem(join(super.outPath, 'lfs.db'));
    return super.prepare();
  }
}

IdbBrowserFileSystemTestContext idbIoFileSystemContext =
    new IdbBrowserFileSystemTestContext();

void main() {
  group('idb_browser', () {
    // All tests
    defineTests(idbIoFileSystemContext);
  });
}
