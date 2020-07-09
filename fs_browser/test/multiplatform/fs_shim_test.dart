import 'package:dev_test/test.dart';
import 'package:fs_shim/fs_shim.dart';

void main() {
  group('import', () {
    test('web', () {
      try {
        fileSystemWeb;
        if (!identical(1, 1.0)) {
          fail('should fail');
        }
      } on UnimplementedError catch (_) {
        // devPrint(_);
      }
    });
  });
}
