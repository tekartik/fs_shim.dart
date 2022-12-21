import 'package:process_run/shell.dart';

Future main() async {
  var shell = Shell();
  await shell.run('''

  dart pub run build_runner test -- -p chrome test/web test/multiplatform

''');
}
