@TestOn('!wasm')
library;

import 'dart:typed_data';

import 'package:fs_shim/fs_idb.dart';
import 'package:fs_shim/src/idb/idb_file_system.dart';
import 'package:fs_shim/src/idb/idb_file_system_storage.dart';
import 'package:fs_shim/src/idb/idb_paging.dart';
import 'package:fs_shim/src/idb/idb_random_access_file.dart';
import 'package:idb_shim/idb.dart';
import 'package:idb_shim/idb_client_memory.dart';
import 'package:idb_shim/utils/idb_utils.dart';

import 'test_common.dart';

void main() {
  test('idbMakePathAbsolute', () {
    expect(idbMakePathAbsolute('/'), '/');
    expect(idbMakePathAbsolute('.'), '/');
    expect(idbMakePathAbsolute('a'), '/a');
    expect(idbMakePathAbsolute('a/../b/c/../d'), '/b/d');
  });

  test('getSegments', () {
    expect(idbPathGetSegments('/./.'), ['/']);
    expect(getSegments('/.'), ['/']);
    expect(getSegments('.'), ['/']);
    expect(getSegments('/'), ['/']);
    expect(getSegments('a'), ['/', 'a']);
    expect(getSegments('/a'), ['/', 'a']);
    expect(getSegments('/a/'), ['/', 'a']);
    expect(segmentsToPath(['/']), '/');
    expect(segmentsToPath(['/', 'a']), '/a');
  });
}
