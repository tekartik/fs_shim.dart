// Copyright (c) 2015, Alexandre Roux. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library fs_shim.fs_src_idb_test;

import 'dart:typed_data';

import 'package:fs_shim/src/idb/idb_paging.dart';

import 'test_common.dart';

void main() {
  test('StreamPartHelper', () {
    var helper = StreamPartHelper(2);

    var bytes = Uint8List.fromList([1, 2, 3]);
    var result = helper.getStreamParts(bytes: bytes, position: 0);
    expect(result.position, 2);
    expect(result.list.map((e) => e.bytes), [
      [1, 2],
    ]);

    bytes = Uint8List.fromList([1, 2, 3]);
    result = helper.getStreamParts(bytes: bytes, position: 0, all: true);
    expect(result.position, 3);
    expect(result.list.map((e) => e.bytes), [
      [1, 2],
      [3]
    ]);
    bytes = Uint8List.fromList([1]);
    result = helper.getStreamParts(bytes: bytes, position: 0);
    expect(result.position, 0);

    bytes = Uint8List.fromList([1]);
    result = helper.getStreamParts(bytes: bytes, position: 0, all: true);
    expect(result.position, 1);

    bytes = Uint8List.fromList([1, 2]);
    result = helper.getStreamParts(bytes: bytes, position: 0);
    expect(result.position, 2);
    expect(result.list.map((e) => e.index), [0]);

    bytes = Uint8List.fromList([1, 2, 3, 4]);
    result = helper.getStreamParts(bytes: bytes, position: 0);
    expect(result.position, 4);
    expect(result.list.map((e) => e.index), [0, 1]);
    expect(result.list.map((e) => e.bytes), [
      [1, 2],
      [3, 4]
    ]);
    result = helper.getStreamParts(bytes: bytes, position: 0, all: true);
    expect(result.position, 4);
    expect(result.list.map((e) => e.index), [0, 1]);
    expect(result.list.map((e) => e.bytes), [
      [1, 2],
      [3, 4]
    ]);

    result = helper.getStreamParts(bytes: bytes, position: 1);
    expect(result.position, 4);
    expect(result.list.map((e) => e.index), [0, 1]);
    expect(result.list.map((e) => e.bytes), [
      [1],
      [2, 3]
    ]);

    result = helper.getStreamParts(bytes: bytes, position: 1, all: true);
    expect(result.position, 5);
    expect(result.list.map((e) => e.index), [0, 1, 2]);
    expect(result.list.map((e) => e.bytes), [
      [1],
      [2, 3],
      [4]
    ]);
  });
}
