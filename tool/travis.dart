import 'dart:io';

import 'package:process_run/shell.dart';
import 'package:pub_semver/pub_semver.dart';

import 'tool_test.dart';

Future main() async {
  var shell = Shell();

  var dartVersion = parsePlatformVersion(Platform.version);
  bool oldListInt = dartVersion <= Version(2, 5, 0, pre: 'dev');

  for (var dir in [
    'fs',
    'fs_browser',
    if (oldListInt) 'fs_node',
    'fs_test',
  ]) {
    shell = shell.pushd(dir);
    await shell.run('''
    
    pub get
    dart tool/travis.dart
    
    ''');
    shell = shell.popd();
  }
}
