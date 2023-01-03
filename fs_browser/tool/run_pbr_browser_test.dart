import 'package:process_run/shell.dart';

Future main() async {
  var shell = Shell();

  // pub run build_runner test -- -p chrome test/multiplatform
  // pub run build_runner test -- -p chrome test/web test/multiplatform
  await shell.run('''

  dart run build_runner test -- -p chrome test/web test/multiplatform

''');
}
