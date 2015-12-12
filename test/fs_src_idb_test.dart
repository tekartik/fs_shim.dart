// Copyright (c) 2015, Alexandre Roux. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library fs_shim.fs_src_idb_test;

import 'package:fs_shim/fs.dart';
import 'package:dev_test/test.dart';
import 'package:idb_shim/idb_client.dart' as idb;
import 'fs_test.dart' as _test;
import 'test_common.dart';
import 'package:path/path.dart';
import 'dart:async';

main() {
  defineTests(memoryFileSystemTestContext);
}

void defineTests(IdbFileSystemTestContext ctx) {
  _test.defineTests(ctx);
  group('format', () {
    test('version', () async {
      await ctx.prepare();
      idb.Database db = ctx.fs.db;
      //TODOexpect(db.version, 2);
      expect(new List.from(db.objectStoreNames)..sort(), ["file", "tree"]);
    });

    Future<int> getStoreSize(idb.Database db, String storeName) async {
      idb.Transaction txn;
      idb.ObjectStore store;
      txn = db.transaction(storeName, idb.idbModeReadOnly);
      store = txn.objectStore(storeName);
      int count = await store.count();
      await txn.completed;
      return count;
    }

    Future<int> getTreeStoreSize(idb.Database db) => getStoreSize(db, "tree");
    Future<int> getFileStoreSize(idb.Database db) => getStoreSize(db, "file");

    test('create_delete_file', () async {
      Directory dir = await ctx.prepare();
      idb.Database db = ctx.fs.db;

      // check the tree size before creating and after creating then deleting
      int treeStoreSize = await getTreeStoreSize(db);
      int fileStoreSize = await getFileStoreSize(db);

      File file = ctx.fs.newFile(join(dir.path, "file"));
      await file.create();

      expect(await getTreeStoreSize(db), treeStoreSize + 1);
      expect(await getFileStoreSize(db), fileStoreSize);

      await file.delete();

      expect(await getTreeStoreSize(db), treeStoreSize);
      expect(await getFileStoreSize(db), fileStoreSize);
    });

    test('write_delete_file', () async {
      Directory dir = await ctx.prepare();
      idb.Database db = ctx.fs.db;

      // check the tree size before creating and after creating then deleting
      int treeStoreSize = await getTreeStoreSize(db);
      int fileStoreSize = await getFileStoreSize(db);

      File file = ctx.fs.newFile(join(dir.path, "file"));
      await file.create();
      var sink = file.openWrite(mode: FileMode.WRITE);
      sink.add('test'.codeUnits);
      await sink.close();

      await file.create();

      expect(await getTreeStoreSize(db), treeStoreSize + 1);
      expect(await getFileStoreSize(db), fileStoreSize + 1);

      await file.delete();

      expect(await getTreeStoreSize(db), treeStoreSize);
      expect(await getFileStoreSize(db), fileStoreSize);
    });
  });
}
