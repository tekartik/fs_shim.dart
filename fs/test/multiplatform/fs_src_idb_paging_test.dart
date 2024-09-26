// Copyright (c) 2015, Alexandre Roux. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library;

import 'dart:typed_data';

import 'package:fs_shim/src/idb/idb_paging.dart';

import 'test_common.dart';

void main() {
  test('getFileParts', () {
    var helper = FilePartHelper(2);

    var bytes = Uint8List.fromList([1, 2, 3]);
    var result = helper.getFileParts(bytes: bytes, start: 0);
    expect(result.position, 2);
    expect(result.list.map((e) => e.bytes), [
      [1, 2],
    ]);

    bytes = Uint8List.fromList([1, 2, 3]);
    result = helper.getFileParts(bytes: bytes, start: 0, all: true);
    expect(result.position, 3);
    expect(result.list.map((e) => e.bytes), [
      [1, 2],
      [3]
    ]);
    bytes = Uint8List.fromList([1]);
    result = helper.getFileParts(bytes: bytes, start: 0);
    expect(result.position, 0);

    bytes = Uint8List.fromList([1]);
    result = helper.getFileParts(bytes: bytes, start: 0, all: true);
    expect(result.position, 1);

    bytes = Uint8List.fromList([1, 2]);
    result = helper.getFileParts(bytes: bytes, start: 0);
    expect(result.position, 2);
    expect(result.list.map((e) => e.index), [0]);

    bytes = Uint8List.fromList([1, 2, 3, 4]);
    result = helper.getFileParts(bytes: bytes, start: 0);
    expect(result.position, 4);
    expect(result.list.map((e) => e.index), [0, 1]);
    expect(result.list.map((e) => e.bytes), [
      [1, 2],
      [3, 4]
    ]);
    result = helper.getFileParts(bytes: bytes, start: 0, all: true);
    expect(result.position, 4);
    expect(result.list.map((e) => e.index), [0, 1]);
    expect(result.list.map((e) => e.bytes), [
      [1, 2],
      [3, 4]
    ]);

    result = helper.getFileParts(bytes: bytes, start: 1);
    expect(result.position, 2);
    expect(result.list.map((e) => e.index), [0]);
    expect(result.list.map((e) => e.start), [0]);
    expect(result.list.map((e) => e.bytes), [
      [2, 3],
    ]);
    result = helper.getFileParts(bytes: bytes, position: 1);
    expect(result.position, 4);
    expect(result.list.map((e) => e.index), [0, 1]);
    expect(result.list.map((e) => e.start), [1, 0]);
    expect(result.list.map((e) => e.bytes), [
      [1],
      [2, 3],
    ]);

    result = helper.getFileParts(bytes: bytes, position: 1, all: true);
    expect(result.position, 5);
    expect(result.list.map((e) => e.index), [0, 1, 2]);
    expect(result.list.map((e) => e.start), [1, 0, 0]);
    expect(result.list.map((e) => e.bytes), [
      [1],
      [2, 3],
      [4]
    ]);

    result = helper.getFileParts(bytes: bytes, start: 1, all: true);
    expect(result.position, 3);
    expect(result.list.map((e) => e.index), [0, 1]);
    expect(result.list.map((e) => e.bytes), [
      [2, 3],
      [4]
    ]);

    result = helper.getFileParts(bytes: bytes, position: 1, all: true);
    expect(result.position, 5);
    expect(result.list.map((e) => e.index), [0, 1, 2]);
    expect(result.list.map((e) => e.bytes), [
      [1],
      [2, 3],
      [4]
    ]);

    expect(result.position, 5);
    bytes = Uint8List.fromList([1, 2, 3, 4, 5, 6, 7]);
    result = helper.getFileParts(
        bytes: bytes, position: 3, start: 2, end: 6, all: true);
    expect(result.list.map((e) => e.index), [1, 2, 3]);
    expect(result.list.map((e) => e.start), [1, 0, 0]);
    expect(result.list.map((e) => e.bytes), [
      [3],
      [4, 5],
      [6]
    ]);

    result =
        helper.getFileParts(bytes: bytes, position: 10, start: 6, all: true);
    expect(result.list.map((e) => e.index), [5]);
    expect(result.list.map((e) => e.bytes), [
      [7],
    ]);
    result =
        helper.getFileParts(bytes: bytes, position: 10, start: 7, all: true);
    expect(result.list, isEmpty);
  });

  test('pageCount', () {
    var helper = FilePartHelper(2);
    expect(helper.pageCountFromSize(0), 0);
    expect(helper.pageCountFromSize(1), 1);
    expect(helper.pageCountFromSize(2), 1);
    expect(helper.pageCountFromSize(3), 2);
  });
  var oneTeraByte = 1024 * 1024 * 1024 * 1024;
  var sixtyFourPageSize = 64 * 1024;
  var pageCount = oneTeraByte ~/ sixtyFourPageSize;

  test('finding padding', () {
    expect(pageCount.toString(), hasLength(8)); // Our padding
    expect(pageCount, 16777216);
    expect(FilePartRef(1, pageCount).toKey(), [1, 16777216]);
  });
  void testRoundTrip(FilePartRef ref) {
    expect(ref, FilePartRef.fromKey(ref.toKey()));
  }

  test('FilePartRef', () {
    var maxSafeInteger = 9007199254740991;
    var filePartRef = FilePartRef(maxSafeInteger, maxSafeInteger);
    expect(filePartRef.toKey(), [9007199254740991, 9007199254740991]);
    filePartRef = FilePartRef(1, 1);
    testRoundTrip(filePartRef);
    expect(filePartRef.toKey(), [1, 1]);
    filePartRef = FilePartRef(-1, -1);
    testRoundTrip(filePartRef);
    expect(filePartRef.toKey(), [-1, -1]);
    if (!isRunningAsJavascript) {
      // const int intMaxValue = 9223372036854775807;
      final intExpectedMaxValue = int.parse('9223372036854775807');
      final intExpectedMinValue = int.parse('-9223372036854775808');
      var intMaxValue = double.maxFinite.toInt();
      filePartRef = FilePartRef(intMaxValue, intMaxValue);
      expect(filePartRef.toKey(), [intExpectedMaxValue, intExpectedMaxValue]);
      filePartRef = FilePartRef(intMaxValue + 1, intMaxValue + 1);
      expect(filePartRef.toKey(),
          [intExpectedMinValue, intExpectedMinValue]); // !!
    }
  });
}
