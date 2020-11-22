import 'dart:io';

import 'package:process_run/shell.dart';
import 'package:pub_semver/pub_semver.dart';

Future main() async {
  var nnbdEnabled = dartVersion > Version(2, 12, 0, pre: '0');
  if (nnbdEnabled) {
    var shell = Shell();

    // var dartVersion = parsePlatformVersion(Platform.version);
    // bool oldListInt = dartVersion <= Version(2, 5, 0, pre: 'dev');

    var packages = [
      'fs',
      // 'fs_browser', // temp nnbd disabled
      // 'fs_node',
      // 'fs_test', // temp nnbd disabled
    ];
    // print('dartVersion: $dartVersion, oldListInt:${oldListInt}');
    print('packages: $packages');
    for (var dir in packages) {
      shell = shell.pushd(dir);
      await shell.run('''
    
    pub get
    dart tool/travis.dart
    
    ''');
      shell = shell.popd();
    }
  } else {
    stderr.writeln('ci test skipped for $dartVersion');
  }
}
