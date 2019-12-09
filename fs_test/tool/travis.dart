import 'package:process_run/shell.dart';

Future<void> main() async {
  final Shell shell = Shell();

  await shell.run('''
# Analyze code
dartanalyzer --fatal-warnings --fatal-infos .
dartfmt -n --set-exit-if-changed .

pub run test -p vm,chrome
pub run build_runner test -- -p vm,chrome

''');
}
