// Copyright (c) 2015, <your name>. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library;

// ignore_for_file: unnecessary_import
import 'package:fs_shim/fs_memory.dart';
import 'package:fs_shim/utils/import_export.dart';

import 'test_common.dart';

var _headersV1 = [
  {'sembast_export': 1, 'version': 1},
  {'store': '_main'},
  [
    'store_file',
    {'name': 'file'},
  ],
  [
    'store_part',
    {
      'name': 'part',
      'keyPath': ['file', 'index'],
    },
  ],
  [
    'store_tree',
    {
      'name': 'tree',
      'autoIncrement': true,
      'indecies': [
        {'name': 'parent', 'keyPath': 'parent'},
        {'name': 'pn', 'keyPath': 'pn', 'unique': true},
      ],
    },
  ],
  [
    'stores',
    ['file', 'part', 'tree'],
  ],
  ['version', 8],
];
var _exportEmptyV1 = [..._headersV1];
void main() {
  test('import_export_empty', () async {
    var fs = newFileSystemMemory();
    expect(await fsIdbExportLines(fs), _exportEmptyV1);
    var fsRead = newFileSystemMemory();
    await fsIdbImport(fsRead, _exportEmptyV1);
    expect(await fsRead.currentDirectory.exists(), isFalse);
  });
  test('import_export_root', () async {
    var fs = newFileSystemMemory();
    await fs.currentDirectory.create(recursive: true);
    var modified = (await fs.currentDirectory.stat()).modified;
    var rootDirExportV1 = [
      ..._headersV1,
      {'store': 'tree'},
      [
        1,
        {
          'name': '/',
          'type': 'dir',
          'modified': modified.toIso8601String(),
          'size': 0,
          'pn': '/',
        },
      ],
    ];
    expect(await fsIdbExportLines(fs), rootDirExportV1);
    var fsRead = newFileSystemMemory();
    await fsIdbImport(fsRead, rootDirExportV1);
    expect(await fsRead.currentDirectory.exists(), isTrue);
  });
  test('import_export_one_file', () async {
    var fs = newFileSystemMemory();
    var file = fs.file('test');
    await file.create(recursive: true);
    await file.writeAsString('123');
    await fs.currentDirectory.create(recursive: true);
    var modified = (await fs.currentDirectory.stat()).modified;
    var fileModified = (await file.stat()).modified;
    var oneFileExportV1 = [
      ..._headersV1,
      {'store': 'file'},
      [
        2,
        {'@Blob': 'MTIz'},
      ],
      {'store': 'tree'},
      [
        1,
        {
          'name': '/',
          'type': 'dir',
          'modified': modified.toIso8601String(),
          'size': 0,
          'pn': '/',
        },
      ],
      [
        2,
        {
          'name': 'test',
          'type': 'file',
          'parent': 1,
          'modified': fileModified.toIso8601String(),
          'size': 3,
          'pn': '1/test',
        },
      ],
    ];
    expect(await fsIdbExportLines(fs), oneFileExportV1);
    var fsRead = newFileSystemMemory();
    await fsIdbImport(fsRead, oneFileExportV1);
    expect(await fsRead.currentDirectory.exists(), isTrue);
  });
}
