import 'copy_tests_from_fs_shim.dart';

Future main() async {
  var dst = '../fs/test/multiplatform';
  var src = 'lib';
  await App(src: src, dst: dst).run();
}
