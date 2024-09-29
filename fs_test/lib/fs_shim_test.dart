// Copyright (c) 2015, <your name>. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library;

import 'package:dev_test/test.dart';
import 'package:fs_shim/fs_shim.dart';

import 'test_common.dart' show isRunningAsJavascript, kDartIsWeb;

void main() {
  group('import', () {
    test('web', () {
      try {
        fileSystemWeb;
        if (!kDartIsWeb) {
          fail('should fail');
        }
      } on UnimplementedError catch (_) {
        // devPrint(_);
      }
    });
    test('io', () {
      try {
        fileSystemIo;
        if (isRunningAsJavascript) {
          fail('should fail');
        }
      } on UnimplementedError catch (_) {
        // devPrint(_);
      }
    });
    test('memory', () {
      fileSystemMemory;
    });
  });
}
