import 'package:process_run/shell.dart';

Future main() async {
  var shell = Shell();

  await shell.run('''
# Analyze code
dartanalyzer --fatal-warnings --fatal-infos .
dartfmt -n --set-exit-if-changed .

# Run tests
pub run test -p vm -j 1 test/io test/multiplatform
pub run test -p chrome -j 1 test/web test/multiplatform
# skip: pub run test -p chrome test/fs_memory_test.dart

# Run tests using build_runner
# skip: failing as of 2019-03-04: pub run build_runner test -- -p vm -j 1
# quick test pub run build_runner test -- -p vm -j 1 test/fs_idb_io_ test.dart
# run everything on chrome

# Work again on 2019-05-14 but not tested anymore and tested
# in fs_browser
# pub run build_runner test -- -p vm -j 1 test/io test/multiplatform
# pub run build_runner test -- -p chrome -j 1 test/web test/multiplatform
''');
}
