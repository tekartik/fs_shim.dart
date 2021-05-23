library fs_shim.utils.read_write;

import 'package:fs_shim/src/common/import.dart';

// Does not fail
Future<File> writeString(File file, String content) async {
  try {
    await file.writeAsString(content, flush: true);
  } catch (_) {
    await file.create(recursive: true);
    await file.writeAsString(content, flush: true);
  }
  return file;
}

// Read string content
Future<String> readString(File file) => file.readAsString();
