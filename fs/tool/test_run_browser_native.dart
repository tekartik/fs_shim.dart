import 'package:process_run/shell.dart';

Future main() async {
  var shell = Shell();

  await shell.run('''

  dart test -p chrome test/web/fs_browser_test.dart

''');
}
