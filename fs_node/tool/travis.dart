import 'package:process_run/shell.dart';

Future<void> main() async {
  final Shell shell = Shell();

  await shell.run('''

dartanalyzer --fatal-warnings --fatal-infos .

pub run test -p node
pub run build_runner test -- -p node

''');
}
