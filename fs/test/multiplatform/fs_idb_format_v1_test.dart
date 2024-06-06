library;

import 'package:fs_shim/src/idb/idb_file_system.dart';
import 'package:idb_shim/idb_client.dart' as idb;
import 'package:idb_shim/idb_shim.dart';
import 'package:idb_shim/utils/idb_import_export.dart';
import 'package:test/test.dart';

import '../test_common.dart';
import 'fs_idb_format_test.dart';
import 'fs_idb_format_v2_test.dart';

void main() {
  fsIdbFormatV1Group(idbFactoryMemoryFs);
}

void fsIdbFormatV1Group(idb.IdbFactory idbFactory) {
  group('idb_format_v1', () {
    test('v1 export', () async {
      var exportMap = exportMapOneAbsoluteFileV1;
      var dbName = 'export_file_v1.sdb';
      await idbFactory.deleteDatabase(dbName);
      var db = await sdbImportDatabase(exportMap, idbFactory, dbName);
      expect(await sdbExportDatabase(db), exportMapOneAbsoluteFileV1);
      db.close();

      var fs = IdbFileSystem(idbFactory, dbName);
      var filePath = 'file.txt';

      var file = fs.file(filePath);
      expect(await file.readAsString(), 'test');

      fs.close();
    }, skip: false);

    test('v1 export simple one absolute file again', () async {
      var dbName = 'import_v1.sdb';
      //devPrint('ds_idb_format_v1_test: idbFactory: $idbFactory');
      await idbFactory.deleteDatabase(dbName);
      var db = await sdbImportDatabase(
          exportMapOneAbsoluteFileV1, idbFactory, dbName);
      expect(await sdbExportDatabase(db), exportMapOneAbsoluteFileV1);
      db.close();

      var fs = IdbFileSystem(idbFactory, dbName);
      var filePath = 'file.txt';

      var file = fs.file(filePath);
      expect(await file.readAsString(), 'test');

      fs.close();
    });
    test('v1 export 2 again', () async {
      var dbName = 'import_v1.sdb';
      // devPrint('ds_idb_format_v1_test: idbFactory: $idbFactory');
      await idbFactory.deleteDatabase(dbName);
      var db = await sdbImportDatabase(exportMapOneFileV1, idbFactory, dbName);
      expect(await sdbExportDatabase(db), exportMapOneFileV1);
      db.close();

      var fs = IdbFileSystem(idbFactory, dbName);
      var filePath = 'file.txt';

      var file = fs.file(filePath);
      expect(await file.readAsString(), 'test');

      fs.close();

      // Re do
      db = await sdbImportDatabase(exportMapOneFileV1, idbFactory, dbName);
      db.close();

      fs = IdbFileSystem(idbFactory, dbName);
      filePath = 'file.txt';

      file = fs.file(filePath);
      expect(await file.readAsString(), 'test');

      filePath = '/file.txt';

      file = fs.file(filePath);
      expect(await file.readAsString(), 'test');

      fs.close();
    });
    // 3 files here
    test('complex1_v1', () async {
      var dbName = 'complex1_v1.db';
      var db =
          await sdbImportDatabase(exportMap3FilesComplex1, idbFactory, dbName);
      db.close();

      var fs = IdbFileSystem(idbFactory, dbName);
      await fsCheckComplex1(fs);
      fs.close();
    });
    test('compare_map', () {
      //  expect(exportMapOneFileV1, exportMapOneAbsoluteFileV1);
    });
  });
}

var exportMapOneFileV2 = {
  'sembast_export': 1,
  'version': 1,
  'stores': [
    mainStoreExportV2,
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
          'name': '/',
          'type': 'DIRECTORY',
          'modified': '2020-10-31T23:27:05.073',
          'size': 0,
          'pn': '/'
        },
        {
          'name': 'file.txt',
          'type': 'file',
          'parent': 1,
          'modified': '2020-10-31T23:27:05.075',
          'size': 4,
          'pn': '1/file.txt',
        }
      ]
    }
  ]
};
var exportMapOneFileV1 = {
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
var exportMapOneAbsoluteFileV1 = {
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
        1
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
          'modified': '2020-11-01T00:12:27.333761',
          'size': 0,
          'pn': '/'
        },
        {
          'name': 'file.txt',
          'type': 'FILE',
          'parent': 1,
          'modified': '2020-11-01T00:12:27.342468',
          'size': 4,
          'pn': '1/file.txt'
        }
      ]
    }
  ]
};

var exportMap3FilesComplex1 = {
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
      'keys': [6, 7, 8],
      'values': [
        [116, 101, 115, 116, 49],
        [116, 101, 115, 116, 50],
        [1, 2, 3]
      ]
    },
    {
      'name': 'tree',
      'keys': [1, 2, 3, 4, 5, 6, 7, 8],
      'values': [
        {
          'name': '/',
          'type': 'DIRECTORY',
          'modified': '2020-11-01T13:00:59.700622',
          'size': 0,
          'pn': '/'
        },
        {
          'name': 'dir1',
          'type': 'DIRECTORY',
          'parent': 1,
          'modified': '2020-11-01T13:00:59.706593',
          'size': 0,
          'pn': '1/dir1'
        },
        {
          'name': 'sub2',
          'type': 'DIRECTORY',
          'parent': 2,
          'modified': '2020-11-01T13:00:59.708479',
          'size': 0,
          'pn': '2/sub2'
        },
        {
          'name': 'nested1',
          'type': 'DIRECTORY',
          'parent': 3,
          'modified': '2020-11-01T13:00:59.709',
          'size': 0,
          'pn': '3/nested1'
        },
        {
          'name': 'sub1',
          'type': 'DIRECTORY',
          'parent': 2,
          'modified': '2020-11-01T13:00:59.721647',
          'size': 0,
          'pn': '2/sub1'
        },
        {
          'name': 'file1.text',
          'type': 'FILE',
          'parent': 5,
          'modified': '2020-11-01T13:00:59.738204',
          'size': 5,
          'pn': '5/file1.text'
        },
        {
          'name': 'file2.text',
          'type': 'FILE',
          'parent': 5,
          'modified': '2020-11-01T13:00:59.743326',
          'size': 5,
          'pn': '5/file2.text'
        },
        {
          'name': 'file3.bin',
          'type': 'FILE',
          'parent': 4,
          'modified': '2020-11-01T13:00:59.749122',
          'size': 3,
          'pn': '4/file3.bin'
        }
      ]
    }
  ]
};
