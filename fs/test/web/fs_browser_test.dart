@TestOn('browser')
// Copyright (c) 2015, Alexandre Roux. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library fs_shim.fs_browser_test;

import 'package:fs_shim/fs_idb.dart';
import 'package:fs_shim/src/idb/idb_file_system.dart';
import 'package:idb_shim/idb_browser.dart';

import '../multiplatform/fs_idb_format_test.dart';
import '../multiplatform/fs_idb_format_v1_test.dart';
import '../multiplatform/fs_idb_test.dart';
import '../multiplatform/platform.dart';
import '../test_common.dart';

FileSystem newFileSystemIdbBrowser([String? name]) =>
    newFileSystemIdb(idbFactoryBrowser, name);

class IdbBrowserFileSystemTestContext extends IdbFileSystemTestContext {
  @override
  final PlatformContext platform = PlatformContextBrowser();
  @override
  late IdbFileSystem fs = () {
    var fs = newFileSystemIdbBrowser()
        as IdbFileSystem; // Needed for initialization (supportsLink)
    return fs;
  }();
}

IdbBrowserFileSystemTestContext idbBrowserFileSystemContext =
    IdbBrowserFileSystemTestContext();

void main() {
  group('idb_browser', () {
    fsIdbFormatGroup(idbFactoryNative);
    fsIdbFormatV1Group(idbFactoryNative);
    // All tests
    defineIdbTests(idbBrowserFileSystemContext);
  });
}
