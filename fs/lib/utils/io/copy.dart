import 'dart:async';
import 'dart:io';

import 'package:fs_shim/fs.dart' as fs;
import 'package:fs_shim/fs_io.dart' as fs_io;
import 'package:fs_shim/utils/copy.dart';
import 'package:fs_shim/utils/copy.dart' as fs;

import 'copy.dart' show CopyOptions;

export 'package:fs_shim/utils/copy.dart'
    show CopyOptions, recursiveLinkOrCopyNewerOptions;

Future<Directory> copyDirectory(Directory src, Directory dst,
    {CopyOptions options}) async {
  return fs_io.unwrapIoDirectory(await fs.copyDirectory(
      fs_io.wrapIoDirectory(src), fs_io.wrapIoDirectory(dst),
      options: options));
}

Future<File> copyFile(File src, File dst, {CopyOptions options}) async {
  return fs_io.unwrapIoFile(await fs.copyFile(
      fs_io.wrapIoFile(src), fs_io.wrapIoFile(dst),
      options: options));
}

// delete a file, no fail
Future deleteFile(File file, {DeleteOptions options}) async {
  return await fs.deleteFile(fs_io.wrapIoFile(file), options: options);
}

/// Delete a directory recursively
Future deleteDirectory(Directory dir, {DeleteOptions options}) =>
    fs.deleteDirectory(fs_io.wrapIoDirectory(dir), options: options);

Future<List<File>> copyDirectoryListFiles(Directory src,
    {CopyOptions options}) async {
  List<File> ioFiles = [];

  List<fs.File> fsFiles = await fs
      .copyDirectoryListFiles(fs_io.wrapIoDirectory(src), options: options);
  for (fs.File fsFile in fsFiles) {
    ioFiles.add(fs_io.unwrapIoFile(fsFile));
  }
  return ioFiles;
}
