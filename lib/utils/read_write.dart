library fs_shim.utils.write;

import 'dart:async';
import '../fs.dart';
import '../src/common/import.dart';

// Does not fail
Future writeString(File file, String content) async {
  try {
    await file.writeAsString(content, flush: true);
  } catch (_) {
    await file.create(recursive: true);
    await file.writeAsString(content, flush: true);
  }
}

// Read string content
Future<String> readString(File file) => file.readAsString();
