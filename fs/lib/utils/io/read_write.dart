library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:fs_shim/fs_io.dart' as fs;
import 'package:fs_shim/utils/read_write.dart' as fs;

var _useCrLf = Platform.isWindows;
var _eol = _useCrLf ? '\r\n' : '\n';

/// Convert a list of lines to a single string with line endings.
String linesToIoString(List<String> lines) {
  if (lines.isEmpty) {
    return '';
  }
  return '${lines.join(_eol)}$_eol';
}

/// Fix lines ending
String stringToIoString(String text) {
  return linesToIoString(linesFromIoString(text));
}

/// Convert a single string with to a list of lines (ignoring line endings).
List<String> linesFromIoString(String text) =>
    LineSplitter.split(text).toList();

/// Extension on [File] to read and write lines.
extension FsShimFileLinesIoFileExt on File {
  /// Read lines from a file.
  Future<List<String>> readLines({Encoding encoding = utf8}) =>
      fs.readLines(fs.wrapIoFile(this), encoding: encoding);

  /// Write lines to a file.
  Future<void> writeLines(List<String> lines,
      {Encoding encoding = utf8}) async {
    fs.unwrapIoFile(await fs.writeLines(fs.wrapIoFile(this), lines,
        encoding: encoding, useCrLf: _useCrLf));
  }
}

/// Write a file string context. Does not fail
Future<File> writeString(File file, String content,
    {Encoding encoding = utf8}) async {
  return fs.unwrapIoFile(
      await fs.writeString(fs.wrapIoFile(file), content, encoding: encoding));
}

/// Write lines content. Does not fail
/// Uses CR/LF if [useCrLf] is true or if null and on windows
Future<File> writeLines(File file, List<String> lines,
    {Encoding encoding = utf8, bool? useCrLf}) async {
  return fs.unwrapIoFile(await fs.writeLines(fs.wrapIoFile(file), lines,
      encoding: encoding, useCrLf: useCrLf));
}

/// Write bytes content. Does not fail
Future<File> writeBytes(File file, Uint8List bytes) async {
  return fs.unwrapIoFile(await fs.writeBytes(fs.wrapIoFile(file), bytes));
}

/// Read string content.
Future<String> readString(File file, {Encoding encoding = utf8}) =>
    fs.readString(fs.wrapIoFile(file), encoding: encoding);

/// Read string content as lines
Future<List<String>> readLines(File file, {Encoding encoding = utf8}) =>
    fs.readLines(fs.wrapIoFile(file), encoding: encoding);

/// Ensure the directory is created and empty.
/// @Deprecated
Future emptyOrCreateDirectory(Directory dir) {
  return dir.emptyOrCreate();
}

/// Empty or create helper
extension DirectoryEmptyOrCreateExt on Directory {
  fs.Directory get _fsDir => fs.wrapIoDirectory(this);

  /// Ensure the directory is created and empty.
  Future<void> emptyOrCreate() async {
    await _fsDir.delete(recursive: true);
    await _fsDir.create(recursive: true);
  }
}
