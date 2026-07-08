@TestOn('vm')
library;

import 'package:dev_build/build_support.dart';
import 'package:process_run/shell.dart';
import 'package:test/test.dart';

/// webdev must be activated.
var webdevReady = () async {
  await checkAndActivateWebdev();
  // setup common alias
  shellEnvironment = ShellEnvironment()
    ..aliases['webdev'] = 'dart pub global run webdev';
}();
void main() {
  test('webdev', () async {
    await webdevReady;
    await run('''
      dart pub get
      webdev build -o example:build
  ''');
  }, timeout: const Timeout(Duration(minutes: 5)));
}
