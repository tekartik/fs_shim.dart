import 'package:process_run/shell.dart';

Future main() async {
  var shell = Shell();

  for (var dir in [
    'fs',
    'fs_node',
    'fs_test',
  ]) {
    shell = shell.pushd(dir);
    await shell.run('dart tool/travis.dart');
    shell = shell.popd();
  }
}
