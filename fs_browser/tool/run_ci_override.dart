import 'package:dev_test/package.dart';
import 'package:process_run/shell.dart';

Future<void> main() async {
  await packageRunCi('.',
      options: PackageRunCiOptions(noTest: true, noOverride: true));
  var shell = Shell();
  // Concurrent test not supported
  await shell.run('dart test -p vm,chrome -j 1');
}
