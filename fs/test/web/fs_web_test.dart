@TestOn('browser')
// Copyright (c) 2015, Alexandre Roux. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.
library;

import 'dart:typed_data';

import 'package:fs_shim/fs_browser.dart';
import 'package:fs_shim/fs_opfs_web.dart';
import 'package:fs_shim/fs_shim.dart';
import 'package:fs_shim/src/idb/idb_file_system.dart';
import 'package:fs_shim/src/idb/idb_file_system_storage.dart';
import 'package:idb_shim/idb_client_native_interop.dart';

import '../multiplatform/fs_idb_format_test.dart';
import '../multiplatform/fs_idb_format_v1_test.dart';
import '../multiplatform/fs_idb_test.dart';
import '../multiplatform/fs_src_idb_file_system_storage_test.dart';
import '../test_common.dart';

FileSystem newFileSystemIdbBrowser([String? name]) =>
    newFileSystemIdb(idbFactoryNative, name);

class IdbBrowserFileSystemTestContext extends IdbFileSystemTestContext {
  IdbBrowserFileSystemTestContext() {
    platform = PlatformContextBrowser();
  }
  @override
  late IdbFileSystem rawFsIdb = () {
    var fs =
        newFileSystemIdbBrowser()
            as IdbFileSystem; // Needed for initialization (supportsLink)
    return fs;
  }();
}

var _index = 0;

class IdbBrowserFileSystemTestContextWithOptions
    extends IdbBrowserFileSystemTestContext {
  IdbBrowserFileSystemTestContextWithOptions({required this.options});
  final FileSystemIdbOptions options;

  @override
  IdbFileSystem get fs => _fs;
  late final IdbFileSystem _fs = () {
    var fs =
        newFileSystemIdbBrowser(
              'db_options_${++_index}',
            ).withIdbOptions(options: options)
            as IdbFileSystem; // Needed for initialization (supportsLink)
    return fs;
  }();
}

IdbBrowserFileSystemTestContext idbBrowserFileSystemContext =
    IdbBrowserFileSystemTestContext();

void main() {
  test('current', () {
    var p = fileSystemWeb.path;
    expect(fileSystemWeb.currentDirectory.path, '/');
    expect(p.absolute('.'), '/.');
    expect(p.isAbsolute('.'), isFalse);
  });
  group('fileSystemWeb page size', () {
    int? pageSizeOf(FileSystem fs) => (fs as FileSystemIdb).idbOptions.pageSize;

    test('defaults', () {
      expect(webDefaultPageSize, 256 * 1024);
      expect(pageSizeOf(fileSystemWeb), webDefaultPageSize);
      expect(pageSizeOf(fileSystemWebNoPaging) ?? 0, 0);
      expect(getFileSystemWeb(), same(fileSystemWeb));
      expect(
        getFileSystemWeb(options: FileSystemIdbOptions.noPage),
        same(fileSystemWebNoPaging),
      );
      expect(
        getFileSystemWeb(options: const FileSystemIdbOptions(pageSize: 0)),
        same(fileSystemWebNoPaging),
      );
      expect(
        pageSizeOf(getFileSystemWeb(options: FileSystemIdbOptions.pageDefault)),
        16 * 1024,
      );
      expect(
        pageSizeOf(newFileSystemWeb(name: 'fs_web_test_default.db')),
        webDefaultPageSize,
      );
      expect(fileSystemDefault, same(fileSystemWeb));
    });

    test('same database, a file converted when written', () async {
      var path = '/fs_web_test/page_size/file.bin';
      var bytes = Uint8List.fromList(
        List.generate(300 * 1024 + 7, (i) => (i * 7) % 251),
      );
      Future<int> filePageSize(FileSystem fs) async =>
          (await (fs as FileSystemIdb).storage.getNode(
            getSegments(path),
            false,
          ))!.filePageSize;

      var noPaging = fileSystemWebNoPaging.file(path);
      var paged = fileSystemWeb.file(path);
      await noPaging.parent.create(recursive: true);
      try {
        // One record, readable with pages.
        await noPaging.writeAsBytes(bytes);
        expect(await filePageSize(fileSystemWeb), 0);
        expect(await paged.readAsBytes(), bytes);
        // Written with pages, readable in one record.
        await paged.writeAsBytes(bytes);
        expect(await filePageSize(fileSystemWeb), webDefaultPageSize);
        expect(await noPaging.readAsBytes(), bytes);
        // An append converts it back.
        var sink = noPaging.openWrite(mode: FileMode.append);
        sink.add([1, 2, 3]);
        await sink.close();
        expect(await filePageSize(fileSystemWeb), 0);
        expect(await paged.readAsBytes(), [...bytes, 1, 2, 3]);
      } finally {
        await noPaging.parent.delete(recursive: true);
      }
    });
  });
  test('storageGetDirectory', () async {
    var handle = await FileSystemOpfsWeb.storageGetDirectory();
    expect(handle, isNotNull);
    //expect(handle.jsObject, isNotNull);
  });
  group('idb_web', () {
    fsIdbMultiFormatGroup(idbFactoryNative);

    fsIdbFormatGroup(idbFactoryNative);
    fsIdbFormatV1Group(idbFactoryNative);
    // All tests
    defineIdbTests(idbBrowserFileSystemContext);
    defineIdbTypesFileSystemStorageTests(idbBrowserFileSystemContext);
    defineIdbTests(
      IdbBrowserFileSystemTestContextWithOptions(
        options: const FileSystemIdbOptions(pageSize: 2),
      ),
    );
    defineIdbTests(
      IdbBrowserFileSystemTestContextWithOptions(
        options: const FileSystemIdbOptions(pageSize: 16 * 1024),
      ),
    );
  });
}
