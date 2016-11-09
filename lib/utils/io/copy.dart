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

Future<List<File>> copyDirectoryListFiles(Directory src,
    {CopyOptions options}) async {
  List<File> ioFiles = [];

  List<fs.File> fsFiles = await fs
      .copyDirectoryListFiles(fs.wrapIoDirectory(src), options: options);
  for (fs.File fsFile in fsFiles) {
    ioFiles.add(fs.unwrapIoFile(fsFile));
  }
  return ioFiles;
}
