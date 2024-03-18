import 'dart:core' as core;

export 'setup_stub.dart' if (dart.library.js_interop) 'setup_web.dart';

var print = doPrint;

void doPrint(core.Object? msg) {
  core.print(msg);
}
