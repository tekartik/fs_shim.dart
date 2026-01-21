library;

import 'package:fs_shim/fs_idb.dart';
import 'package:fs_shim/src/idb/idb_file_system.dart';
import 'package:fs_shim/src/idb/idb_file_system_storage.dart';
import 'package:fs_shim/src/idb/idb_paging.dart';
import 'package:idb_shim/idb_client.dart' as idb;

import 'fs_src_idb_file_system_storage_test.dart';
import 'test_common.dart';

void main() {
  defineIdbTests(memoryFileSystemTestContext);
  // devWarning(defineIdbTests(MemoryFileSystemTestContext(options: FileSystemIdbOptions(pageSize: 2)));
}

void defineIdbTests(IdbFileSystemTestContext ctx) {
  defineIdbFileSystemStorageTests(ctx);
  group('idb', () {
    var fs = ctx.fs;
    var p = fs.path;
    test('path', () {
      expect(p.separator, '/');
      if (idbPathContextIsPosix) {
        expect(p.current, '/');
      } else {
        expect(p.current, '.');
        expect(p.isAbsolute('./.'), isTrue); // !!
        expect(p.absolute('.'), './.'); // !!
      }

      expect(p.absolute('/'), '/');

      expect(p.isAbsolute(p.absolute('.')), isTrue);
    });

    test('version', () async {
      await ctx.prepare();
      final db = ctx.fs.db!;
      expect(db.version, 8);
      // If this fails, delete .dart_tool/fs_shim/test folder
      expect(List<String>.from(db.objectStoreNames)..sort(), [
        'file',
        'part',
        'tree',
      ]);
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

    Future<int> getTreeStoreSize(idb.Database db) =>
        getStoreSize(db, treeStoreName);
    Future<int> getFileStoreSize(idb.Database db) =>
        getStoreSize(db, fileStoreName);
    Future<int> getPartStoreSize(idb.Database db) =>
        getStoreSize(db, partStoreName);

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
      final partStoreSize = await getPartStoreSize(db);

      File file = ctx.fs.file(fs.path.join(dir.path, 'file'));

      // Write dummy file
      await file.writeAsString('test', flush: true);

      await file.create();

      expect(await getTreeStoreSize(db), treeStoreSize + 1);
      if (!ctx.fs.idbOptions.hasPageSize || !idbSupportsV2Format) {
        expect(await getFileStoreSize(db), fileStoreSize + 1);
        expect(await getPartStoreSize(db), partStoreSize);
      } else {
        expect(await getFileStoreSize(db), fileStoreSize);
        expect(
          await getPartStoreSize(db),
          partStoreSize +
              pageCountFromSizeAndPageSize(4, ctx.fs.idbOptions.pageSize!),
        );
      }

      await file.delete();

      expect(await getTreeStoreSize(db), treeStoreSize);
      expect(await getFileStoreSize(db), fileStoreSize);
    });

    test('current', () async {
      if (idbPathContextIsPosix) {
        expect(fs.currentDirectory.path, '/');
      } else {
        expect(fs.currentDirectory.path, '.');
      }

      expect(fs.currentDirectory.absolute.path, '/');
    });
  });
}
