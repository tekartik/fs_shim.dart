library fs_shim.utils.io.read_write;


import 'dart:io';

import 'package:fs_shim/fs_io.dart' as fs;
import 'package:fs_shim/utils/read_write.dart' as fs;
import 'package:fs_shim/utils/src/utils_impl.dart' as fs;

// Does not fail
Future<File> writeString(File file, String content) async {
  return fs.unwrapIoFile(await fs.writeString(fs.wrapIoFile(file), content));
}

// Read string content
Future<String> readString(File file) => fs.readString(fs.wrapIoFile(file));

Future emptyOrCreateDirectory(Directory dir) {
  return fs.emptyOrCreateDirectory(fs.wrapIoDirectory(dir));
}
