import 'dart:typed_data';

import 'package:fs_shim/src/common/import.dart';
import 'package:fs_shim/src/platform/platform.dart';

/// Write a string content. Does not fail
Future<File> writeString(File file, String content,
    {Encoding encoding = utf8}) async {
  try {
    await file.writeAsString(content, flush: true, encoding: encoding);
  } catch (_) {
    await file.create(recursive: true);
    await file.writeAsString(content, flush: true, encoding: encoding);
  }
  return file;
}

/// Write bytes content. Does not fail
Future<File> writeBytes(File file, Uint8List bytes) async {
  try {
    await file.writeAsBytes(bytes, flush: true);
  } catch (_) {
    await file.create(recursive: true);
    await file.writeAsBytes(bytes, flush: true);
  }
  return file;
}

/// Write lines content. Does not fail
/// Uses CR/LF if [useCrLf] is true or if null and on windows
Future<File> writeLines(File file, List<String> lines,
    {Encoding encoding = utf8, bool? useCrLf}) {
  if (lines.isEmpty) {
    return writeString(file, '', encoding: encoding);
  }
  var lf = (useCrLf ?? platformIsIoWindows) ? '\r\n' : '\n';
  return writeString(file, '${lines.join(lf)}$lf', encoding: encoding);
}

/// Read string content
Future<String> readString(File file, {Encoding encoding = utf8}) =>
    file.readAsString(encoding: encoding);

/// Read string content
Future<List<String>> readLines(File file, {Encoding encoding = utf8}) async {
  var text = await readString(file, encoding: encoding);
  return LineSplitter.split(text).toList();
}
