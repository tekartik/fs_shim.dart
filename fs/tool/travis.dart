import 'package:process_run/shell.dart';

Future main() async {
  var shell = Shell();

  await shell.run('''
# Analyze code
dartanalyzer --fatal-warnings --fatal-infos .

# Run tests
pub run test -p vm -j 1
pub run test -p chrome -j 1
# skip: pub run test -p chrome test/fs_memory_test.dart

# Run tests using build_runner
# skip: failing as of 2019-03-04: pub run build_runner test -- -p vm -j 1
# quick test pub run build_runner test -- -p vm -j 1 test/fs_idb_io_ test.dart
# run everything on chrome

# pub run build_runner test -- -p vm -j 1
pub run build_runner test -- -p chrome -j 1
''');
}
