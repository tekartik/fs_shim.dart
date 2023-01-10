import 'package:path/path.dart';
import 'package:process_run/shell.dart';

Future main() async {
  var shell = Shell();

  shell = shell.pushd(join('..', 'fs'));
  await shell.run('''

dart pub get
dart test -p vm test/multiplatform/fs_idb_format_test.dart

    ''');
  shell = shell.pushd(join('..', 'fs_io'));
  await shell.run('''

dart pub get
dart test -p vm test/fs_idb_io_test.dart test/fs_io_test.dart

    ''');
  shell = shell.popd();
  shell = shell.pushd(join('..', 'fs_browser'));
  await shell.run('''

dart pub get
dart test -p chrome test/web/fs_browser_page_size_2_test.dart

    ''');
  shell = shell.popd();
}
