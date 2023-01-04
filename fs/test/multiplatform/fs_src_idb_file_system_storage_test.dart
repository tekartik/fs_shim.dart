// Copyright (c) 2015, Alexandre Roux. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library fs_shim.fs_src_idb_test;

import 'dart:typed_data';

import 'package:fs_shim/fs_idb.dart';
import 'package:fs_shim/src/idb/idb_file_system.dart';
import 'package:fs_shim/src/idb/idb_file_system_storage.dart';
import 'package:idb_shim/idb.dart';
import 'package:idb_shim/idb_client_memory.dart';
import 'package:idb_shim/utils/idb_utils.dart';

import 'test_common.dart';

void main() {
  test('getSegments', () {
    expect(getSegments('/'), ['/']);
    expect(getSegments('a'), ['/', 'a']);
    expect(getSegments('/a'), ['/', 'a']);
    expect(segmentsToPath(['/']), '/');
    expect(segmentsToPath(['/', 'a']), '/a');
  });
  defineIdbFileSystemStorageTests(memoryFileSystemTestContext);
  defineIdbFileSystemStorageTests(
      MemoryFileSystemTestContext(options: FileSystemIdbOptions(pageSize: 2)));
}

var _index = 0;
void defineIdbFileSystemStorageTests(IdbFileSystemTestContext ctx) {
  var p = idbPathContext;

  Future<IdbFileSystemStorage> newStorage() async {
    final storage = IdbFileSystemStorage(
        ctx.fs.idbFactory, 'idb_storage_${++_index}',
        options: FileSystemIdbOptions(pageSize: ctx.fs.idbOptions.pageSize));
    try {
      await storage.delete().timeout(const Duration(seconds: 5));
    } catch (e) {
      print('error $e');
    }
    await storage.ready;
    return storage;
  }

  group('idb_file_system_storage', () {
    test('ready', () async {
      var storage = await newStorage();
      await storage.ready;
    });

    test('add_get_with_parent', () async {
      // debugIdbShowLogs = devWarning(true);
      var storage = await newStorage();
      final entity = Node.directory(null, 'dir');
      await storage.addNode(entity);
      expect(entity.id, 1);

      expect(await storage.getChildNode(null, 'dir', false), entity);
      expect(await storage.getChildNode(null, 'dummy', false), isNull);
    });

    test('add_get_entity', () async {
      var storage = await newStorage();
      final node = Node.directory(null, 'dir');
      await storage.addNode(node);
      expect(node.id, 1);

      expect(await storage.getNode(['dir'], false), node);
      expect(await storage.getNode(['dummy'], false), isNull);
    });

    test('add_search', () async {
      var storage = await newStorage();
      final node = Node.directory(null, 'dir');
      await storage.addNode(node);
      expect(node.id, 1);

      var result = await storage.searchNode(['dir'], false);
      expect(result.matches, isTrue);
      expect(result.match, node);
      expect(result.highest, node);
      expect(result.depthDiff, 0);

      result = await storage.searchNode(['dummy'], false);
      expect(result.matches, isFalse);
      expect(result.match, isNull);
      expect(result.highest, isNull);
      expect(result.depthDiff, 1);
    });

    test('link', () async {
      var storage = await newStorage();
      final dir = Node.directory(null, 'dir');
      await storage.addNode(dir);
      final link = Node.link(null, 'link', targetSegments: ['dir']);
      await storage.addNode(link);

      expect(await storage.getNode(['link'], false), link);
      expect(await storage.getNode(['link'], true), dir);
      expect(await storage.getNode(['dir'], false), dir);
      expect(await storage.getNode(['dir'], true), dir);
    });

    test('link_link', () async {
      var storage = await newStorage();
      final dir = Node.directory(null, 'dir');
      await storage.addNode(dir);
      final link = Node.link(null, 'link', targetSegments: ['dir']);
      await storage.addNode(link);
      final link2 = Node.link(null, 'link2', targetSegments: ['link']);
      await storage.addNode(link2);

      expect(await storage.getNode(['link2'], false), link2);
      expect(await storage.getNode(['link2'], true), dir);
      expect(await storage.getNode(['dir'], false), dir);
      expect(await storage.getNode(['dir'], true), dir);
    });

    test('child_node', () async {
      var storage = await newStorage();
      final dir = Node.directory(null, p.separator);
      await storage.addNode(dir);
      final file = Node.file(dir, 'file');
      await storage.addNode(file);

      expect(await storage.getNode([p.separator, 'file'], false), file);
      expect(await storage.getNode([p.separator, 'file'], true), file);
      expect(await storage.getChildNode(dir, 'file', true), file);
      expect(await storage.getChildNode(dir, 'file', false), file);

      final link =
          Node.link(dir, 'link', targetSegments: [p.separator, 'file']);
      await storage.addNode(link);

      expect(await storage.getNode([p.separator, 'link'], false), link);
      expect(await storage.getNode([p.separator, 'link'], true), file);
    });

    test('file_in_dir', () async {
      var storage = await newStorage();
      final top = Node.directory(null, p.separator);
      await storage.addNode(top);
      final dir = Node.directory(top, 'dir');
      await storage.addNode(dir);
      final file = Node.file(dir, 'file');
      await storage.addNode(file);
      final link =
          Node.link(top, 'link', targetSegments: [p.separator, 'dir', 'file']);
      await storage.addNode(link);

      expect(await storage.getNode([p.separator, 'link'], true), file);

      expect(await storage.getChildNode(top, 'link', false), link);
      expect(await storage.getNode([p.separator, 'link'], false), link);
      expect(await storage.getChildNode(top, 'link', true), file);
    });

    test('getParentName', () {
      final top = Node.directory(null, p.separator)..id = 1;
      expect(getParentName(top, 'test'), '1/test');
    });
    group('ready', () {
      late IdbFileSystemStorage storage;
      setUp(() async {
        storage = await newStorage();
        await storage.ready;
      });

      test('writeDataV1', () async {
        var db = storage.db!;

        expect(await getFileEntries(db), []);
        var txn = getWriteAllTransaction(db);
        var node = await storage.txnSetFileDataV1(
            txn,
            Node.node(FileSystemEntityType.file, null, 'test', id: 1),
            Uint8List.fromList([1, 2, 3]));
        expect(node.pageSize, 0);
        var fileEntries = await getFileEntries(db);
        expect(fileEntries, [
          {
            'key': 1,
            'value': [1, 2, 3]
          }
        ]);
        // expect(fileEntries[0]['value'], isA<Uint8List>());
        expect(await getTreeEntries(db), [
          {
            'key': 1,
            'value': {'name': 'test', 'type': 'file', 'size': 3, 'pn': '/test'}
          }
        ]);
        txn = getWriteAllTransaction(db);
        await storage.txnDeleteFileDataV1(txn, node.fileId);
      });

      test('writeDataV2', () async {
        // debugIdbShowLogs = devWarning(true);

        var db = storage.db!;
        expect(await getFileEntries(db), []);
        var txn = getWriteAllTransaction(db);
        var node = await storage.txnSetFileDataV2(
            txn,
            Node.node(FileSystemEntityType.file, null, 'test', id: 1),
            Uint8List.fromList([1, 2, 3]));
        expect(node.pageSize, isNotNull);
        expect(node.pageSize, storage.pageSize);
        expect(await getFileEntries(db), []);

        expect(await getTreeEntries(db), [
          {
            'key': 1,
            'value': {
              'name': 'test',
              'type': 'file',
              'size': 3,
              if (ctx.fs.idbOptions.hasPageSize)
                'ps': ctx.fs.idbOptions.pageSize,
              'pn': '/test'
            }
          }
        ]);

        var partEntries = await getPartEntries(db);
        var pageSize = storage.options.pageSize ?? 0;
        // devPrint('pageSize: $pageSize');
        if (pageSize == 0 || pageSize >= 3) {
          expect(partEntries, [
            {
              'key': 1,
              'value': {
                'index': 0,
                'file': 1,
                'content': [1, 2, 3]
              }
            }
          ]);
        } else {
          // minimum is 2
          expect(partEntries, [
            {
              'key': 1,
              'value': {
                'index': 0,
                'file': 1,
                'content': [1, 2]
              }
            },
            {
              'key': 2,
              'value': {
                'index': 1,
                'file': 1,
                'content': [3]
              }
            }
          ]);
        }
        //expect(partEntries[0]['value'], isA<Uint8List>());
        txn = getWriteAllTransaction(db);
        await storage.txnDeleteFileDataV2(txn, node.fileId);
      });
    });
    group('ready pageSize 2', () {
      late IdbFileSystemStorage storage;
      setUp(() async {
        storage = IdbFileSystemStorage(newIdbFactoryMemory(), 'idb_storage',
            options: FileSystemIdbOptions(pageSize: 2));
        await storage.ready;
      });

      test('writeDataV2 page size 2', () async {
        var db = storage.db!;
        expect(await getFileEntries(db), []);
        var txn = getWriteAllTransaction(db);
        var node = await storage.txnSetFileDataV2(
            txn,
            Node.node(FileSystemEntityType.file, null, 'test', id: 1),
            Uint8List.fromList([1, 2, 3]));
        expect(node.pageSize, isNotNull);
        expect(node.pageSize, storage.pageSize);
        expect(await getFileEntries(db), []);
        expect(await getTreeEntries(db), [
          {
            'key': 1,
            'value': {
              'name': 'test',
              'type': 'file',
              'size': 3,
              'ps': 2,
              'pn': '/test'
            }
          }
        ]);

        var partEntries = await getPartEntries(db);
        expect(partEntries, [
          {
            'key': 1,
            'value': {
              'index': 0,
              'file': 1,
              'content': [1, 2]
            }
          },
          {
            'key': 2,
            'value': {
              'index': 1,
              'file': 1,
              'content': [3]
            }
          }
        ]);
        //expect(partEntries[0]['value'], isA<Uint8List>());
      });
    });
    test('getSegments', () {
      expect(getSegments('/'), ['/']);
      expect(getSegments('/a'), ['/', 'a']);
      expect(getSegments('/a/b'), ['/', 'a', 'b']);
      expect(getSegments('/a/b/'), ['/', 'a', 'b']);
      expect(getSegments('.'), ['/']);
      expect(getSegments('./.'), ['/']);
      expect(getSegments('././a'), ['/', 'a']);
      expect(getSegments('/a/../b'), ['/', 'b']);
      expect(getSegments('/a/b/../c'), ['/', 'a', 'c']);
      expect(getSegments('/a/b/../../c'), ['/', 'c']);
    });
  });
}

Transaction getWriteAllTransaction(Database db) => db.transactionList(
    [treeStoreName, fileStoreName, partStoreName], idbModeReadWrite);

Future<List<Map>> getEntriesFromCursor(Stream<CursorWithValue> cwv) async {
  var list = await cursorToList(cwv);
  // devPrint('list $list');
  return list.map((row) => {'key': row.key, 'value': row.value}).toList();
}

Future<List<Map>> getTreeEntries(Database db) async {
  var txn = db.transaction(treeStoreName, idbModeReadOnly);
  var treeObjectStore = txn.objectStore(treeStoreName);
  try {
    return await getEntriesFromCursor(
        treeObjectStore.openCursor(autoAdvance: true));
  } finally {
    await txn.completed;
  }
}

Future<List<Map>> getPartEntries(Database db) async {
  var txn = db.transaction(partStoreName, idbModeReadOnly);
  var store = txn.objectStore(partStoreName);
  try {
    return await getEntriesFromCursor(store.openCursor(autoAdvance: true));
  } finally {
    await txn.completed;
  }
}

Future<List<Map>> getFileEntries(Database db) async {
  var txn = db.transaction(fileStoreName, idbModeReadOnly);
  var fileObjectStore = txn.objectStore(fileStoreName);
  try {
    return await getEntriesFromCursor(
        fileObjectStore.openCursor(autoAdvance: true));
  } finally {
    await txn.completed;
  }
}
