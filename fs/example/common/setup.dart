import 'dart:core' as core;

export 'setup_stub.dart' if (dart.library.html) 'setup_web.dart';

var print = doPrint;

void doPrint(core.Object? msg) {
  core.print(msg);
}
