library;

import 'package:fs_shim/fs_opfs_web.dart';
import 'package:fs_shim/fs_shim.dart';
import 'package:fs_shim/src/common/env_utils.dart';
import 'package:test/test.dart';

void main() {
  group('import', () {
    test('web', () {
      try {
        fileSystemWeb;
        if (!kFsDartIsWeb) {
          fail('should fail');
        }
      } on UnimplementedError catch (_) {
        // devPrint(_);
      }
    });
    test('web opfs', () {
      try {
        fileSystemOpfsWeb;
        if (!kFsDartIsWeb) {
          fail('should fail');
        }
      } on UnimplementedError catch (_) {
        // devPrint(_);
      }
    });
    test('io', () {
      try {
        fileSystemIo;
        if (kFsDartIsWeb) {
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
