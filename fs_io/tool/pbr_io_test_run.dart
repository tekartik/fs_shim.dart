import 'package:process_run/shell.dart';

Future main() async {
  var shell = Shell();
  await shell.run('''
  dart run build_runner test -- -p vm test
''');
}
