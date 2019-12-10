import 'package:process_run/shell.dart';

Future<void> main() async {
  final shell = Shell();

  await shell.run('''
# Analyze code
dartanalyzer --fatal-warnings --fatal-infos .
dartfmt -n --set-exit-if-changed .

# 2019-12-10 remove fs_node_test for travis
pub run test -p node ^
  test/node/fs_dir_node_test.dart ^
  test/node/fs_file_node_test.dart ^
  test/node/fs_file_stat_test.dart ^
  test/node/fs_file_system_node_test.dart ^
  test/node/fs_link_node_test.dart ^
  # test/node/fs_node_test.dart ^
  test/node/raw_node_io_test.dart ^
  test/multiplatform

# pub run build_runner test -- -p node

''');
}
