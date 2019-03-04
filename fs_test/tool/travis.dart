import 'package:process_run/shell.dart';

Future<void> main() async {
  final Shell shell = Shell();

  await shell.run('''
pub get

dartanalyzer --fatal-warnings --fatal-infos .

# failing for now 2018-06-30 
pub run test -p vm,chrome

pub run test -p vm
pub run build_runner test -- -p vm,chrome

''');
}
