// Copyright (c) 2015, Alexandre Roux. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library fs_shim.test.multiplatform.fs_idb_test;

import 'package:fs_shim/fs.dart';
import 'package:idb_shim/idb_client.dart' as idb;

import 'fs_src_idb_file_system_storage_test.dart';
import 'fs_test.dart' as fs_test;
import 'test_common.dart';

void main() {
  defineTests(memoryFileSystemTestContext);
}

void defineTests(IdbFileSystemTestContext ctx) {
  fs_test.defineTests(ctx);
  defineIdbFileSystemStorageTests(ctx);
  group('idb', () {
    var fs = ctx.fs;
    test('version', () async {
      await ctx.prepare();
      final db = ctx.fs.db!;
      expect(db.version, 7);
      // If this fails, delete .dart_tool/fs_shim/test folder
      expect(List.from(db.objectStoreNames)..sort(), ['file', 'part', 'tree']);
    });

    Future<int> getStoreSize(idb.Database db, String storeName) async {
      idb.Transaction txn;
      idb.ObjectStore store;
      txn = db.transaction(storeName, idb.idbModeReadOnly);
      store = txn.objectStore(storeName);
      final count = await store.count();
      await txn.completed;
      return count;
    }

    Future<int> getTreeStoreSize(idb.Database db) => getStoreSize(db, 'tree');
    Future<int> getFileStoreSize(idb.Database db) => getStoreSize(db, 'file');

    test('create_delete_file', () async {
      final dir = await ctx.prepare();
      final db = ctx.fs.db!;

      // check the tree size before creating and after creating then deleting
      final treeStoreSize = await getTreeStoreSize(db);
      final fileStoreSize = await getFileStoreSize(db);

      File file = ctx.fs.file(fs.path.join(dir.path, 'file'));
      await file.create();

      expect(await getTreeStoreSize(db), treeStoreSize + 1);
      expect(await getFileStoreSize(db), fileStoreSize);

      await file.delete();

      expect(await getTreeStoreSize(db), treeStoreSize);
      expect(await getFileStoreSize(db), fileStoreSize);
    });

    test('write_delete_file', () async {
      final dir = await ctx.prepare();
      final db = ctx.fs.db!;

      // check the tree size before creating and after creating then deleting
      final treeStoreSize = await getTreeStoreSize(db);
      final fileStoreSize = await getFileStoreSize(db);

      File file = ctx.fs.file(fs.path.join(dir.path, 'file'));

      // Write dummy file
      await file.writeAsString('test', flush: true);

      await file.create();

      expect(await getTreeStoreSize(db), treeStoreSize + 1);
      expect(await getFileStoreSize(db), fileStoreSize + 1);

      await file.delete();

      expect(await getTreeStoreSize(db), treeStoreSize);
      expect(await getFileStoreSize(db), fileStoreSize);
    });
  });
}
