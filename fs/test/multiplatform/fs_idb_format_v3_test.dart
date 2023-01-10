// Copyright (c) 2015, Alexandre Roux. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.
@TestOn('vm || chrome')
library fs_shim.test.multiplatform.fs_idb_format_v1_test;

import 'package:fs_shim/src/idb/idb_file_system.dart';
import 'package:idb_shim/idb_client.dart' as idb;
import 'package:idb_shim/idb_shim.dart';
import 'package:idb_shim/utils/idb_import_export.dart';
import 'package:test/test.dart';

import '../test_common.dart';
import 'fs_idb_format_v2_test.dart';

void main() {
  fsIdbFormatV2Group(idbFactoryMemoryFs);
}

void fsIdbFormatV2Group(idb.IdbFactory idbFactory) {
  group('idb_format_v3', () {
    test('v2 export page size 0', () async {
      var exportMap = rawExportOneFileV2PageSize0;
      var dbName = 'export_file_v2.sdb';
      await idbFactory.deleteDatabase(dbName);
      var db = await sdbImportDatabase(exportMap, idbFactory, dbName);
      expect(await sdbExportDatabase(db), exportMap);
      db.close();

      var fs = IdbFileSystem(idbFactory, dbName);
      var filePath = 'file.txt';

      var file = fs.file(filePath);
      expect(await file.readAsString(), 'test');

      fs.close();
    }, skip: false);
    test('v3 export page size 2', () async {
      var exportMap = rawExportOneFileV3PageSize2;
      var dbName = 'export_file_v3.sdb';
      await idbFactory.deleteDatabase(dbName);
      var db = await sdbImportDatabase(exportMap, idbFactory, dbName);
      expect(await sdbExportDatabase(db), rawExportOneFileV3PageSize2);
      db.close();

      var fs = IdbFileSystem(idbFactory, dbName);
      var filePath = 'file.txt';

      var file = fs.file(filePath);
      expect(await file.readAsString(), 'test');

      fs.close();
    }, skip: false);

    test('v2 page size 1024 import', () async {
      var exportMap = rawExportOneFileV3PageSize1024;
      var dbName = 'export_file_v3_1024.sdb';
      await idbFactory.deleteDatabase(dbName);
      var db = await sdbImportDatabase(exportMap, idbFactory, dbName);
      expect(await sdbExportDatabase(db), exportMap);
      db.close();

      var fs = IdbFileSystem(idbFactory, dbName);
      var filePath = 'file.txt';

      var file = fs.file(filePath);
      expect(await file.readAsString(), 'test');

      fs.close();
    }, skip: false);
  });
}

var rawExportOneFileV3PageSize2 = {
  'sembast_export': 1,
  'version': 1,
  'stores': [
    {
      'name': '_main',
      'keys': ['store_file', 'store_part', 'store_tree', 'stores', 'version'],
      'values': [
        {'name': 'file'},
        {
          'name': 'part',
          'keyPath': ['file', 'index']
        },
        {
          'name': 'tree',
          'autoIncrement': true,
          'indecies': [
            {'name': 'parent', 'keyPath': 'parent'},
            {'name': 'pn', 'keyPath': 'pn', 'unique': true}
          ]
        },
        ['file', 'part', 'tree'],
        8
      ]
    },
    {
      'name': 'part',
      'keys': [1, 2],
      'values': [
        {
          'index': 0,
          'file': 2,
          'content': {'@Blob': 'dGU='}
        },
        {
          'index': 1,
          'file': 2,
          'content': {'@Blob': 'c3Q='}
        }
      ]
    },
    {
      'name': 'tree',
      'keys': [1, 2],
      'values': [
        {
          'name': '/',
          'type': 'dir',
          'modified': '2023-01-06T17:14:04.528980Z',
          'size': 0,
          'pn': '/'
        },
        {
          'name': 'file.txt',
          'type': 'file',
          'ps': 2,
          'parent': 1,
          'modified': '2023-01-06T17:14:04.535381Z',
          'size': 4,
          'pn': '1/file.txt'
        }
      ]
    }
  ]
};
var mainStoreExportV3 = {
  'name': '_main',
  'keys': ['store_file', 'store_part', 'store_tree', 'stores', 'version'],
  'values': [
    {'name': 'file'},
    {
      'name': 'part',
      'keyPath': ['file', 'index']
    },
    {
      'name': 'tree',
      'autoIncrement': true,
      'indecies': [
        {'name': 'parent', 'keyPath': 'parent'},
        {'name': 'pn', 'keyPath': 'pn', 'unique': true}
      ]
    },
    ['file', 'part', 'tree'],
    8
  ]
};

var rawExportOneFileV3PageSize1024 = {
  'sembast_export': 1,
  'version': 1,
  'stores': [
    {
      'name': '_main',
      'keys': ['store_file', 'store_part', 'store_tree', 'stores', 'version'],
      'values': [
        {'name': 'file'},
        {
          'name': 'part',
          'keyPath': ['file', 'index']
        },
        {
          'name': 'tree',
          'autoIncrement': true,
          'indecies': [
            {'name': 'parent', 'keyPath': 'parent'},
            {'name': 'pn', 'keyPath': 'pn', 'unique': true}
          ]
        },
        ['file', 'part', 'tree'],
        8
      ]
    },
    {
      'name': 'part',
      'keys': [1],
      'values': [
        {
          'index': 0,
          'file': 2,
          'content': {'@Blob': 'dGVzdA=='}
        }
      ]
    },
    {
      'name': 'tree',
      'keys': [1, 2],
      'values': [
        {
          'name': '/',
          'type': 'dir',
          'modified': '2023-01-06T17:18:52.466915Z',
          'size': 0,
          'pn': '/'
        },
        {
          'name': 'file.txt',
          'type': 'file',
          'ps': 1024,
          'parent': 1,
          'modified': '2023-01-06T17:18:52.473463Z',
          'size': 4,
          'pn': '1/file.txt'
        }
      ]
    }
  ]
};
