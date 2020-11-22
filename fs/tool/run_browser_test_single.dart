// @dart=2.9
import 'package:process_run/shell.dart';

// dev file ok to modify when debugging.
Future main() async {
  var shell = Shell();

  // pub run build_runner test -- -p chrome test/multiplatform
  // pub run build_runner test -- -p chrome test/web test/multiplatform
  await shell.run('''

  # pub run build_runner test -- -p chrome test/multiplatform/fs_shim_test.dart
  pub run build_runner test -- -p chrome test/web/fs_browser_test.dart
  # pub run build_runner test -- -p chrome test/multiplatform/fs_src_idb_file_system_storage_test.dart

''');
}
