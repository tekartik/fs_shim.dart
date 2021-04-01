import 'package:dev_test/package.dart';
import 'package:path/path.dart';

var topDir = '..';

Future<void> main() async {
  for (var dir in [
    'fs',
    'fs_browser',
    'fs_io',
    'fs_test',
  ]) {
    var path = join(topDir, dir);
    // concurrent test are not supported
    await packageRunCi(path);
  }
}
