// Copyright (c) 2015, <your name>. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library fs_shim.test.path_exp_test;

import 'test_common.dart';
import 'package:path/path.dart';

main() {
  group('path_exp', () {
    test('windows', () {
      expect(windows.basename('a/b'), 'b');
      expect(windows.basename('a\\b'), 'b');
    });
    test('posix', () {
      expect(posix.basename('a/b'), 'b');
      expect(posix.basename('a\\b'),
          'a\\b'); // !!!! posix does not convert windows style correctly
    });

    test('convert', () {
      String path = 'c:\\windows\\system';
      expect(windows.joinAll(windows.split(path)), path);
      String posixPath = posix.joinAll(windows.split(path));
      expect(windows.joinAll(posix.split(posixPath)), path);
      expect(
          windows.joinAll(windows.split(posixPath)), path); // !event this works
    });
  });
}
