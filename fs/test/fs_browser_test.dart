@TestOn("browser")
// Copyright (c) 2015, Alexandre Roux. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library fs_shim.fs_browser_test;

import 'dart:async';

import 'package:dev_test/test.dart';
import 'package:fs_shim/fs.dart';
import 'package:fs_shim/fs_idb.dart';
import 'package:fs_shim/src/idb/idb_file_system.dart';
import 'package:idb_shim/idb_browser.dart';
import 'package:path/path.dart';
import 'package:tekartik_platform/context.dart';
import 'package:tekartik_platform_browser/context_browser.dart';

import 'fs_idb_test.dart';
import 'test_common.dart';

FileSystem newIdbBrowserFileSystem([String name]) =>
    newIdbFileSystem(idbBrowserFactory, name);

class IdbBrowserFileSystemTestContext extends IdbFileSystemTestContext {
  @override
  final PlatformContext platform = platformContextBrowser;
  @override
  IdbFileSystem fs = newIdbBrowserFileSystem()
      as IdbFileSystem; // Needed for initialization (supportsLink)
  IdbBrowserFileSystemTestContext();

  @override
  Future<Directory> prepare() {
    fs =
        newIdbBrowserFileSystem(join(super.outPath, 'lfs.db')) as IdbFileSystem;
    return super.prepare();
  }
}

IdbBrowserFileSystemTestContext idbBrowserFileSystemContext =
    IdbBrowserFileSystemTestContext();

void main() {
  group('idb_browser', () {
    // All tests
    defineTests(idbBrowserFileSystemContext);
  });
}
