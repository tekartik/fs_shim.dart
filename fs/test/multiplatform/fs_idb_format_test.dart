// Copyright (c) 2015, Alexandre Roux. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.
@TestOn('vm || chrome')
library fs_shim.test.multiplatform.fs_idb_format_test;

import 'dart:typed_data';

//import 'package:test/test.dart';
import 'package:dev_test/test.dart';
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
              [116, 101, 115, 116]
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
                [116, 101, 115, 116]
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
      //timeout: devWarning(const Timeout(Duration(hours: 1)))
    );
  });

  test('v1 export 2', () async {
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
            [116, 101, 115, 116]
          ]
        },
        {
          'name': 'tree',
          'keys': [1, 2],
          'values': [
            {
              'name': '/',
              'type': 'DIRECTORY',
              'modified': '2020-10-31T23:27:05.073',
              'size': 0,
              'pn': '/'
            },
            {
              'name': 'file.txt',
              'type': 'FILE',
              'parent': 1,
              'modified': '2020-10-31T23:27:05.075',
              'size': 4,
              'pn': '1/file.txt'
            }
          ]
        }
      ]
    };
    var dbName = 'import_v1.sdb';
    // devPrint('ds_idb_format_test: idbFactory: $idbFactory');
    await idbFactory.deleteDatabase(dbName);
    var db = await sdbImportDatabase(exportMap, idbFactory, dbName);
    db.close();

    var fs = IdbFileSystem(idbFactory, dbName);
    var filePath = 'file.txt';

    var file = fs.file(filePath);
    expect(await file.readAsString(), 'test');

    fs.close();
  });
}
