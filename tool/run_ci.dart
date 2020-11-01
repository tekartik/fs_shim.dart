import 'package:dev_test/package.dart';

Future main() async {
  for (var dir in [
    '.',
    'fs',
    'fs_browser',
    'fs_io',
    // 'fs_node',
    'fs_test',
  ]) {
    await packageRunCi(dir);
  }
}
