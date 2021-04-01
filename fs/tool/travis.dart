import 'dart:io';

import 'package:process_run/shell.dart';
import 'package:dev_test/package.dart';

Future main() async {
  var shell = Shell();

  await packageRunCi('.');
  exit(0);
  // ignore: dead_code
  await shell.run(''' 
# Analyze code
dart analyze --fatal-warnings --fatal-infos .
dart format -o none --set-exit-if-changed .


# Run tests -j 1 is important!
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

dartdoc
''');
}
