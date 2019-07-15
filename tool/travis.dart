import 'package:process_run/shell.dart';

Future main() async {
  var shell = Shell();

  // var dartVersion = parsePlatformVersion(Platform.version);
  // bool oldListInt = dartVersion <= Version(2, 5, 0, pre: 'dev');

  var packages = [
    'fs',
    'fs_browser',
    'fs_node',
    'fs_test',
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
}
