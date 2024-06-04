@TestOn('!wasm')
library;

import 'package:fs_shim/src/idb/idb_file_system.dart';
import 'package:fs_shim/src/idb/idb_file_system_storage.dart';

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
