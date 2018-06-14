library fs_shim.utils.read_write;

import 'dart:async';
import 'dart:io';

import '../../fs_io.dart' as fs;
import '../read_write.dart' as fs;
import '../src/utils_impl.dart' as fs;

// Does not fail
Future<File> writeString(File file, String content) async {
  return fs.unwrapIoFile(await fs.writeString(fs.wrapIoFile(file), content));
}

// Read string content
Future<String> readString(File file) => fs.readString(fs.wrapIoFile(file));

Future emptyOrCreateDirectory(Directory dir) {
  return fs.emptyOrCreateDirectory(fs.wrapIoDirectory(dir));
}
