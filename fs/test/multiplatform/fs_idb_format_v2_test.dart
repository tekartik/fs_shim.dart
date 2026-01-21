library;

import 'package:fs_shim/src/idb/idb_file_system.dart';
import 'package:idb_shim/idb_client.dart' as idb;
import 'package:idb_shim/utils/idb_import_export.dart';
import 'package:test/test.dart';

import '../test_common.dart';

void main() {
  fsIdbFormatV2Group(idbFactoryMemoryFs);
}

void fsIdbFormatV2Group(idb.IdbFactory idbFactory) {
  group('idb_format_v2', () {
    test('v2 export page size 0', () async {
      var exportMap = rawExportOneFileV2PageSize0;
      var dbName = 'export_file_v2.sdb';
      await idbFactory.deleteDatabase(dbName);
      var db = await sdbImportDatabase(exportMap, idbFactory, dbName);
      expect(await sdbExportDatabase(db), exportMap);
      db.close();

      var fs = IdbFileSystem(idbFactory, dbPath: dbName);
      var filePath = 'file.txt';

      var file = fs.file(filePath);
      expect(await file.readAsString(), 'test');

      fs.close();
    }, skip: false);
    test('v2 export page size 2', () async {
      var exportMap = rawExportOneFileV2PageSize2;
      var dbName = 'export_file_v2.sdb';
      await idbFactory.deleteDatabase(dbName);
      var db = await sdbImportDatabase(exportMap, idbFactory, dbName);
      expect(await sdbExportDatabase(db), rawExportOneFileV2PageSize2);
      db.close();

      var fs = IdbFileSystem(idbFactory, dbPath: dbName);
      var filePath = 'file.txt';

      var file = fs.file(filePath);
      expect(await file.readAsString(), 'test');

      fs.close();
    }, skip: true); // no longer supported

    test('v2 page size 1024 import', () async {
      var exportMap = rawExportOneFilePageSize1024;
      var dbName = 'export_file_v2_1024.sdb';
      await idbFactory.deleteDatabase(dbName);
      var db = await sdbImportDatabase(exportMap, idbFactory, dbName);
      expect(await sdbExportDatabase(db), exportMap);
      db.close();

      var fs = IdbFileSystem(idbFactory, dbPath: dbName);
      var filePath = 'file.txt';

      var file = fs.file(filePath);
      expect(await file.readAsString(), 'test');

      fs.close();
    }, skip: true); // no longer supported
  });
}

// page size 2
var rawExportOneFileV2PageSize2 = {
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
          'autoIncrement': true,
          'indecies': [
            {
              'name': 'part_index',
              'keyPath': ['file', 'index'],
              'unique': true,
            },
          ],
        },
        {
          'name': 'tree',
          'autoIncrement': true,
          'indecies': [
            {'name': 'parent', 'keyPath': 'parent'},
            {'name': 'pn', 'keyPath': 'pn', 'unique': true},
          ],
        },
        ['file', 'part', 'tree'],
        7,
      ],
    },
    {
      'name': 'part',
      'keys': [1, 2],
      'values': [
        {
          'index': 0,
          'file': 2,
          'content': {'@Blob': 'dGU='},
        },
        {
          'index': 1,
          'file': 2,
          'content': {'@Blob': 'c3Q='},
        },
      ],
    },
    {
      'name': 'tree',
      'keys': [1, 2],
      'values': [
        {
          'name': '/',
          'type': 'dir',
          'modified': '2023-01-03T11:29:31.923123Z',
          'size': 0,
          'pn': '/',
        },
        {
          'name': 'file.txt',
          'type': 'file',
          'ps': 2,
          'parent': 1,
          'modified': '2023-01-03T11:29:31.923412Z',
          'size': 4,
          'pn': '1/file.txt',
        },
      ],
    },
  ],
};

var rawExportOneFilePageSize1024 = {
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
          'autoIncrement': true,
          'indecies': [
            {
              'name': 'part_index',
              'keyPath': ['file', 'index'],
              'unique': true,
            },
          ],
        },
        {
          'name': 'tree',
          'autoIncrement': true,
          'indecies': [
            {'name': 'parent', 'keyPath': 'parent'},
            {'name': 'pn', 'keyPath': 'pn', 'unique': true},
          ],
        },
        ['file', 'part', 'tree'],
        7,
      ],
    },
    {
      'name': 'part',
      'keys': [1],
      'values': [
        {
          'index': 0,
          'file': 2,
          'content': {'@Blob': 'dGVzdA=='},
        },
      ],
    },
    {
      'name': 'tree',
      'keys': [1, 2],
      'values': [
        {
          'name': '/',
          'type': 'dir',
          'modified': '2023-01-03T14:10:34.117682Z',
          'size': 0,
          'pn': '/',
        },
        {
          'name': 'file.txt',
          'type': 'file',
          'ps': 1024,
          'parent': 1,
          'modified': '2023-01-03T14:10:34.117891Z',
          'size': 4,
          'pn': '1/file.txt',
        },
      ],
    },
  ],
};

var rawExportOneFileV2PageSize0 = {
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
          'autoIncrement': true,
          'indecies': [
            {
              'name': 'part_index',
              'keyPath': ['file', 'index'],
              'unique': true,
            },
          ],
        },
        {
          'name': 'tree',
          'autoIncrement': true,
          'indecies': [
            {'name': 'parent', 'keyPath': 'parent'},
            {'name': 'pn', 'keyPath': 'pn', 'unique': true},
          ],
        },
        ['file', 'part', 'tree'],
        7,
      ],
    },
    {
      'name': 'file',
      'keys': [2],
      'values': [
        {'@Blob': 'dGVzdA=='},
      ],
    },
    {
      'name': 'tree',
      'keys': [1, 2],
      'values': [
        {
          'name': '/',
          'type': 'dir',
          'modified': '2023-01-03T14:13:59.687055Z',
          'size': 0,
          'pn': '/',
        },
        {
          'name': 'file.txt',
          'type': 'file',
          'parent': 1,
          'modified': '2023-01-03T14:13:59.692498Z',
          'size': 4,
          'pn': '1/file.txt',
        },
      ],
    },
  ],
};

var mainStoreExportV2 = {
  'name': '_main',
  'keys': ['store_file', 'store_part', 'store_tree', 'stores', 'version'],
  'values': [
    {'name': 'file'},
    {
      'name': 'part',
      'autoIncrement': true,
      'indecies': [
        {
          'name': 'part_index',
          'keyPath': ['file', 'index'],
          'unique': true,
        },
      ],
    },
    {
      'name': 'tree',
      'autoIncrement': true,
      'indecies': [
        {'name': 'parent', 'keyPath': 'parent'},
        {'name': 'pn', 'keyPath': 'pn', 'unique': true},
      ],
    },
    ['file', 'part', 'tree'],
    7,
  ],
};
