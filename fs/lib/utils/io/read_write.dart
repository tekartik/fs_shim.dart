library fs_shim.utils.io.read_write;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:fs_shim/fs_io.dart' as fs;
import 'package:fs_shim/utils/read_write.dart' as fs;
import 'package:fs_shim/utils/src/utils_impl.dart' as fs;

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
Future emptyOrCreateDirectory(Directory dir) {
  return fs.emptyOrCreateDirectory(fs.wrapIoDirectory(dir));
}
