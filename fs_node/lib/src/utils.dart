import 'package:tekartik_fs_node/src/import_common.dart';

int statusFromMessage(String message) {
  // Error: ENOENT: no such file or directory, scandir '.dart_tool/fs_shim_node/test_out/fs_node/file/create_recursive'
  if (message.toLowerCase().contains('no such file or directory')) {
    return FileSystemException.statusNotFound;
  }
  return null;
}
