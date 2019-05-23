import 'package:fs_shim/fs.dart';
import 'package:tekartik_fs_node/src/utils.dart';
import 'package:test/test.dart';

void main() {
  group('file_system_exception_node', () {
    test('fromString', () {
      var message =
          "ENOENT: no such file or directory, scandir '.dart_tool/fs_shim_node/test_out/fs_node/file/create_recursive'";
      expect(statusFromMessage(message), FileSystemException.statusNotFound);
    });
  });
}
