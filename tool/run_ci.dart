import 'dart:io';

import 'package:dev_test/package.dart';
import 'package:process_run/shell.dart';
import 'package:pub_semver/pub_semver.dart';

Future main() async {
  var nnbdEnabled = dartVersion > Version(2, 12, 0, pre: '0');
  if (nnbdEnabled) {
    for (var dir in [
      // '.',
      'fs',
      'fs_browser',
      'fs_io',
      // 'fs_node',
      'fs_test',
    ]) {
      // concurrent test are not supported
      await packageRunCi(dir, noTest: true);
      var shell = Shell(workingDirectory: dir);
      await shell.run('dart test -p vm,chrome -j 1');
    }
  } else {
    stderr.writeln('ci test skipped for $dartVersion');
  }
}
