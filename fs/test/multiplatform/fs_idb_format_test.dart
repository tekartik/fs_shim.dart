// Copyright (c) 2015, Alexandre Roux. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.
@TestOn('vm || chrome')
library fs_shim.test.multiplatform.fs_idb_format_test;

import 'dart:typed_data';

//import 'package:test/test.dart';
import 'package:test/test.dart';
import 'package:fs_shim/fs.dart';
import 'package:fs_shim/src/idb/idb_file_system.dart';
import 'package:idb_shim/idb_client.dart' as idb;
import 'package:idb_shim/idb_shim.dart';
import 'package:idb_shim/utils/idb_import_export.dart';
import 'package:idb_shim/utils/idb_utils.dart';

import 'test_common.dart';

//import 'test_common.dart';

void main() {
  fsIdbFormatGroup(idbFactoryMemory);
}

void fsIdbFormatGroup(idb.IdbFactory idbFactory) {
  group('idb_format', () {
    test('v1_format absolute test file', () async {
      var dbName = 'v1_format_absolute_text_file.db';
      await idbFactory.deleteDatabase(dbName);
      var fs = IdbFileSystem(idbFactory, dbName);
      var filePath = '${fs.path.separator}file.txt';

      var file = fs.file(filePath);
      await file.writeAsString('test');
      var fileStat = await file.stat();
      var dirStat = await fs.directory(fs.path.separator).stat();
      fs.close();

      var db = await idbFactory.open(dbName);
      expect(db.objectStoreNames.toSet(), {'file', 'tree'});
      var txn = db.transaction(['file', 'tree'], idbModeReadOnly);
      var treeObjectStore = txn.objectStore('tree');
      var list =
          await cursorToList(treeObjectStore.openCursor(autoAdvance: true));
      expect(list.map((row) => {'key': row.key, 'value': row.value}), [
        {
          'key': 1,
          'value': {
            'name': fs.path.separator,
            'type': 'DIRECTORY',
            'modified': dirStat.modified.toIso8601String(),
            'size': 0,
            'pn': fs.path.separator,
          }
        },
        {
          'key': 2,
          'value': {
            'name': 'file.txt',
            'type': 'FILE',
            'parent': 1,
            'modified': fileStat.modified.toIso8601String(),
            'size': 4,
            'pn': fs.path.join('1', 'file.txt')
          }
        }
      ]);
      var fileObjectStore = txn.objectStore('file');
      list = await cursorToList(fileObjectStore.openCursor(autoAdvance: true));
      expect(list.map((row) => {'key': row.key, 'value': row.value}), [
        {
          'key': 2,
          'value': Uint8List.fromList([116, 101, 115, 116])
        }
      ]);
      var exportMap = {
        'sembast_export': 1,
        'version': 1,
        'stores': [
          {
            'name': '_main',
            'keys': ['store_file', 'store_tree', 'stores', 'version'],
            'values': [
              {'name': 'file'},
              {
                'name': 'tree',
                'autoIncrement': true,
                'indecies': [
                  {'name': 'parent', 'keyPath': 'parent'},
                  {'name': 'pn', 'keyPath': 'pn', 'unique': true}
                ]
              },
              ['file', 'tree'],
              6
            ]
          },
          {
            'name': 'file',
            'keys': [2],
            'values': [
              {'@Blob': 'dGVzdA=='}
            ]
          },
          {
            'name': 'tree',
            'keys': [1, 2],
            'values': [
              {
                'name': fs.path.separator,
                'type': 'DIRECTORY',
                'modified': dirStat.modified.toIso8601String(),
                'size': 0,
                'pn': fs.path.separator
              },
              {
                'name': 'file.txt',
                'type': 'FILE',
                'parent': 1,
                'modified': fileStat.modified.toIso8601String(),
                'size': 4,
                'pn': fs.path.join('1', 'file.txt'),
              }
            ]
          }
        ]
      };
      // devPrint(jsonPretty(exportMap));
      expect(await sdbExportDatabase(db), exportMap);
      db.close();
    });
    test(
      'v1_format',
      () async {
        var dbName = 'v1_format.db';
        await idbFactory.deleteDatabase(dbName);
        var fs = IdbFileSystem(idbFactory, dbName);
        var filePath = '${fs.path.separator}file.txt';

        var file = fs.file(filePath);
        await file.writeAsString('test');
        var fileStat = await file.stat();
        var dirStat = await fs.directory(fs.path.separator).stat();
        fs.close();

        // Reopen file system
        fs = IdbFileSystem(idbFactory, dbName);
        //devPrint(await fs.list('/', recursive: true).toList());
        file = fs.file(filePath);

        expect(await file.readAsString(), 'test');
        fs.close();

        var db = await idbFactory.open(dbName);
        expect(db.objectStoreNames.toSet(), {'file', 'tree'});
        var txn = db.transaction(['file', 'tree'], idbModeReadOnly);
        var treeObjectStore = txn.objectStore('tree');
        var list =
            await cursorToList(treeObjectStore.openCursor(autoAdvance: true));
        expect(list.map((row) => {'key': row.key, 'value': row.value}), [
          {
            'key': 1,
            'value': {
              'name': fs.path.separator,
              'type': 'DIRECTORY',
              'modified': dirStat.modified.toIso8601String(),
              'size': 0,
              'pn': fs.path.separator,
            }
          },
          {
            'key': 2,
            'value': {
              'name': 'file.txt',
              'type': 'FILE',
              'parent': 1,
              'modified': fileStat.modified.toIso8601String(),
              'size': 4,
              'pn': fs.path.join('1', 'file.txt')
            }
          }
        ]);
        var fileObjectStore = txn.objectStore('file');
        list =
            await cursorToList(fileObjectStore.openCursor(autoAdvance: true));
        expect(list.map((row) => {'key': row.key, 'value': row.value}), [
          {
            'key': 2,
            'value': Uint8List.fromList([116, 101, 115, 116])
          }
        ]);
        var exportMap = {
          'sembast_export': 1,
          'version': 1,
          'stores': [
            {
              'name': '_main',
              'keys': ['store_file', 'store_tree', 'stores', 'version'],
              'values': [
                {'name': 'file'},
                {
                  'name': 'tree',
                  'autoIncrement': true,
                  'indecies': [
                    {'name': 'parent', 'keyPath': 'parent'},
                    {'name': 'pn', 'keyPath': 'pn', 'unique': true}
                  ]
                },
                ['file', 'tree'],
                6
              ]
            },
            {
              'name': 'file',
              'keys': [2],
              'values': [
                {'@Blob': 'dGVzdA=='}
              ]
            },
            {
              'name': 'tree',
              'keys': [1, 2],
              'values': [
                {
                  'name': fs.path.separator,
                  'type': 'DIRECTORY',
                  'modified': dirStat.modified.toIso8601String(),
                  'size': 0,
                  'pn': fs.path.separator
                },
                {
                  'name': 'file.txt',
                  'type': 'FILE',
                  'parent': 1,
                  'modified': fileStat.modified.toIso8601String(),
                  'size': 4,
                  'pn': fs.path.join('1', 'file.txt'),
                }
              ]
            }
          ]
        };
        expect(await sdbExportDatabase(db), exportMap);
        db.close();

        // devPrint(exportMap);
        db = await sdbImportDatabase(exportMap, idbFactory, dbName);
        expect(await sdbExportDatabase(db), exportMap);
        db.close();

        fs = IdbFileSystem(idbFactory, dbName);
        // devPrint(await fs.list('/', recursive: true).toList());
        file = fs.file(filePath);

        expect(await file.readAsString(), 'test');
        fs.close();
      },
      //solo: true,
      // Temp timeout
      // timeout: devWarning(const Timeout(Duration(hours: 1)))
      //
    );
  });

  test('complex1', () async {
    var dbName = 'complex1.db';
    var dbNameImported = 'complex1_imported.db';
    await idbFactory.deleteDatabase(dbName);
    var fs = IdbFileSystem(idbFactory, dbName);
    await fs
        .directory(fs.path.join('dir1', 'sub2', 'nested1'))
        .create(recursive: true);
    await fs.directory(fs.path.join('dir1', 'sub1')).create(recursive: true);
    await fs
        .file(fs.path.join('dir1', 'sub1', 'file1.text'))
        .writeAsString('test1');
    await fs
        .file(fs.path.join('dir1', 'sub1', 'file2.text'))
        .writeAsString('test2');
    await fs
        .file(fs.path.join('dir1', 'sub2', 'nested1', 'file3.bin'))
        .writeAsBytes(Uint8List.fromList([1, 2, 3]));

    await fsCheckComplex1(fs);
    fs.close();

    var db = await idbFactory.open(dbName);
    var exportMap = await sdbExportDatabase(db);
    // devPrint(jsonPretty(exportMap)); print for copying/pasting for import
    db.close();

    db = await sdbImportDatabase(exportMap, idbFactory, dbNameImported);
    expect(await sdbExportDatabase(db), exportMap);
    db.close();

    fs = IdbFileSystem(idbFactory, dbNameImported);
    await fsCheckComplex1(fs);
    fs.close();
  });
}

Future<void> fsCheckComplex1(FileSystem fs) async {
  expect(
      await fs
          .file(fs.path.join('dir1', 'sub2', 'nested1', 'file3.bin'))
          .readAsBytes(),
      [1, 2, 3]);
  expect(
      await fs.file(fs.path.join('dir1', 'sub1', 'file2.text')).readAsString(),
      'test2');
  expect(
      await fs.file(fs.path.join('dir1', 'sub1', 'file1.text')).readAsBytes(),
      [116, 101, 115, 116, 49]);
}
