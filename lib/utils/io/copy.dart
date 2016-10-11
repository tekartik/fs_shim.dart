import 'dart:async';
import 'dart:io';

import '../../fs_io.dart' as fs;
import '../copy.dart' as fs;
import 'copy.dart' show CopyOptions;

export '../copy.dart' show CopyOptions, recursiveLinkOrCopyNewerOptions;

Future<Directory> copyDirectory(Directory src, Directory dst,
    {CopyOptions options}) async {
  return fs.unwrapIoDirectory(await fs.copyDirectory(
      fs.wrapIoDirectory(src), fs.wrapIoDirectory(dst),
      options: options));
}

Future<File> copyFile(File src, File dst, {CopyOptions options}) async {
  return fs.unwrapIoFile(await fs
      .copyFile(fs.wrapIoFile(src), fs.wrapIoFile(dst), options: options));
}
