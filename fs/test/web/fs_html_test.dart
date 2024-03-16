@TestOn('browser')
// Copyright (c) 2015, Alexandre Roux. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library;

import 'package:fs_shim/fs_idb.dart';
import 'package:fs_shim/src/idb/idb_file_system.dart';
import 'package:idb_shim/idb_client_native_html.dart';

import '../multiplatform/fs_idb_format_test.dart';
import '../multiplatform/fs_idb_format_v1_test.dart';
import '../multiplatform/fs_idb_test.dart';
import '../multiplatform/fs_src_idb_file_system_storage_test.dart';
import '../test_common.dart';

FileSystem newFileSystemIdbBrowser([String? name]) =>
    newFileSystemIdb(idbFactoryNative, name);

class IdbBrowserFileSystemTestContext extends IdbFileSystemTestContext {
  @override
  late IdbFileSystem rawFsIdb = () {
    var fs = newFileSystemIdbBrowser()
        as IdbFileSystem; // Needed for initialization (supportsLink)
    return fs;
  }();

  IdbBrowserFileSystemTestContext() {
    platform = PlatformContextBrowser();
  }
}

var _index = 0;

class IdbBrowserFileSystemTestContextWithOptions
    extends IdbBrowserFileSystemTestContext {
  final FileSystemIdbOptions options;

  @override
  IdbFileSystem get fs => _fs;
  late final IdbFileSystem _fs = () {
    var fs = newFileSystemIdbBrowser('db_options_${++_index}')
            .withIdbOptions(options: options)
        as IdbFileSystem; // Needed for initialization (supportsLink)
    return fs;
  }();

  IdbBrowserFileSystemTestContextWithOptions({required this.options});
}

IdbBrowserFileSystemTestContext idbBrowserFileSystemContext =
    IdbBrowserFileSystemTestContext();

void main() {
  group('idb_web', () {
    fsIdbMultiFormatGroup(idbFactoryNative);

    fsIdbFormatGroup(idbFactoryNative);
    fsIdbFormatV1Group(idbFactoryNative);
    // All tests
    defineIdbTests(idbBrowserFileSystemContext);
    defineIdbTypesFileSystemStorageTests(idbBrowserFileSystemContext);
    defineIdbTests(IdbBrowserFileSystemTestContextWithOptions(
        options: const FileSystemIdbOptions(pageSize: 2)));
    defineIdbTests(IdbBrowserFileSystemTestContextWithOptions(
        options: const FileSystemIdbOptions(pageSize: 16 * 1024)));
  });
}
