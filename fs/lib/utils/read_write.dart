import 'dart:typed_data';

import 'package:fs_shim/src/common/bytes_utils.dart';
import 'package:fs_shim/src/common/import.dart';
import 'package:fs_shim/src/platform/platform.dart';

/// Write a string content. Does not fail
Future<File> writeString(
  File file,
  String content, {
  Encoding encoding = utf8,
}) async {
  try {
    await file.writeAsString(content, flush: true, encoding: encoding);
  } catch (e) {
    await file.parent.create(recursive: true);
    await file.writeAsString(content, flush: true, encoding: encoding);
  }
  return file;
}

/// Write bytes content. Does not fail
Future<File> writeBytes(File file, Uint8List bytes) async {
  try {
    await file.writeAsBytes(bytes, flush: true);
  } catch (_) {
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes, flush: true);
  }
  return file;
}

/// Write the content of [stream] to [file].
///
/// The parent directory is created if missing. The file is truncated first
/// ([FileMode.write]) and flushed before the returned future completes.
///
/// On a file system without random access support
/// ([FileSystem.supportsRandomAccess] is false, e.g. OPFS), the whole stream
/// is buffered in memory and written at once with [File.writeAsBytes];
/// otherwise the stream is piped to [File.openWrite].
Future<File> streamToFile(Stream<List<int>> stream, File file) async {
  final parent = file.parent;
  if (!await parent.exists()) {
    await parent.create(recursive: true);
  }
  if (!file.fs.supportsRandomAccess) {
    await file.writeAsBytes(await streamToBytes(stream), flush: true);
    return file;
  }
  final sink = file.openWrite();
  try {
    await sink.addStream(stream);
    await sink.flush();
  } catch (_) {
    try {
      await sink.close();
    } catch (_) {
      // Keep the original error
    }
    rethrow;
  }
  await sink.close();
  return file;
}

/// Write lines content. Does not fail
/// Uses CR/LF if [useCrLf] is true or if null and on windows
Future<File> writeLines(
  File file,
  List<String> lines, {
  Encoding encoding = utf8,
  bool? useCrLf,
}) {
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

/// Empty or create helper
extension DirectoryEmptyOrCreateExt on Directory {
  /// Ensure the directory is created and empty.
  Future<void> emptyOrCreate() async {
    if (await exists()) {
      try {
        await delete(recursive: true);
      } catch (_) {
        // ignore
      }
    }
    await create(recursive: true);
  }
}

/// Stream to file helper
extension FileStreamToFileExt on File {
  /// Write the content of [stream] to this file, creating the parent
  /// directory if missing. See [streamToFile].
  Future<File> writeStream(Stream<List<int>> stream) =>
      streamToFile(stream, this);
}
