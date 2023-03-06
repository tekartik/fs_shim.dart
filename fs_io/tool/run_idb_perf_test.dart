import 'package:process_run/shell.dart';

Future main() async {
  var shell = Shell();
  await shell.run('''
  dart test -p vm test/fs_idb_io_perf_test_manual.dart test/fs_idb_sqflite_perf_test_manual.dart
''');
}
