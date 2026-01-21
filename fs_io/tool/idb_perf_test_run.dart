import 'package:process_run/shell.dart';

Future main() async {
  var shell = Shell();
  await shell.run('''
  dart test -p vm tool/fs_idb_io_perf_test_run.dart tool/fs_idb_sqflite_perf_test_run.dart
''');
}
