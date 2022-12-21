// Copyright (c) 2015, Alexandre Roux. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library fs_shim.fs_src_idb_test;

import 'dart:typed_data';

import 'package:fs_shim/fs.dart';
import 'package:fs_shim/src/idb/idb_file_system.dart';
import 'package:fs_shim/src/idb/idb_file_system_storage.dart';
import 'package:idb_shim/idb.dart';
import 'package:idb_shim/idb_client_memory.dart';
import 'package:idb_shim/utils/idb_utils.dart';

import 'test_common.dart';

void main() {
  defineIdbFileSystemStorageTests(memoryFileSystemTestContext);
}

void defineIdbFileSystemStorageTests(IdbFileSystemTestContext ctx) {
  var p = idbPathContext;
  var index = 0;
  Future<IdbFileSystemStorage> newStorage() async {
    final storage =
        IdbFileSystemStorage(ctx.fs.idbFactory, 'idb_storage_${++index}');
    await storage.delete();
    await storage.ready;
    return storage;
  }

  group('idb_file_system_storage', () {
    test('ready', () async {
      var storage = await newStorage();
      await storage.ready;
    });

    test('add_get_with_parent', () async {
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
        storage = IdbFileSystemStorage(newIdbFactoryMemory(), 'idb_storage',
            pageSize: 1024);
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
        expect(node.pageSize, null);
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
      });

      test('writeDataV2', () async {
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
              'ps': 1024,
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
              'content': [1, 2, 3]
            }
          }
        ]);
        //expect(partEntries[0]['value'], isA<Uint8List>());
      });
    });
  });
}

Transaction getWriteAllTransaction(Database db) => db.transactionList(
    [treeStoreName, fileStoreName, partStoreName], idbModeReadWrite);

Future<List<Map>> getEntriesFromCursor(Stream<CursorWithValue> cwv) async {
  var list = await cursorToList(cwv);
  return list.map((row) => {'key': row.key, 'value': row.value}).toList();
}

Future<List<Map>> getTreeEntries(Database db) async {
  var txn = db.transaction(treeStoreName, idbModeReadOnly);
  var treeObjectStore = txn.objectStore(treeStoreName);
  return await getEntriesFromCursor(
      treeObjectStore.openCursor(autoAdvance: true));
}

Future<List<Map>> getPartEntries(Database db) async {
  var txn = db.transaction(partStoreName, idbModeReadOnly);
  var store = txn.objectStore(partStoreName);
  return await getEntriesFromCursor(store.openCursor(autoAdvance: true));
}

Future<List<Map>> getFileEntries(Database db) async {
  var txn = db.transaction(fileStoreName, idbModeReadOnly);
  var fileObjectStore = txn.objectStore(fileStoreName);
  return await getEntriesFromCursor(
      fileObjectStore.openCursor(autoAdvance: true));
}
