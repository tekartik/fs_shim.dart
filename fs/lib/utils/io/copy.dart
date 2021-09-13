import 'dart:io';

import 'package:fs_shim/fs_io.dart' as fs_io;
import 'package:fs_shim/utils/copy.dart';
import 'package:fs_shim/utils/copy.dart' as fs;

export 'package:fs_shim/utils/copy.dart'
    show CopyOptions, recursiveLinkOrCopyNewerOptions;

/// Copy a directory.
Future<Directory> copyDirectory(Directory src, Directory dst,
    {CopyOptions? options}) async {
  return fs_io.unwrapIoDirectory(await fs.copyDirectory(
      fs_io.wrapIoDirectory(src), fs_io.wrapIoDirectory(dst),
      options: options));
}

/// Copy a file.
Future<File> copyFile(File src, File dst, {CopyOptions? options}) async {
  return fs_io.unwrapIoFile(await fs.copyFile(
      fs_io.wrapIoFile(src), fs_io.wrapIoFile(dst),
      options: options));
}

/// delete a file, no fail
Future deleteFile(File file, {DeleteOptions? options}) async {
  return await fs.deleteFile(fs_io.wrapIoFile(file), options: options);
}

/// Delete a directory recursively
Future deleteDirectory(Directory dir, {DeleteOptions? options}) =>
    fs.deleteDirectory(fs_io.wrapIoDirectory(dir), options: options);

/// Copy a list of files in a directory.
Future<List<File>> copyDirectoryListFiles(Directory src,
    {CopyOptions? options}) async {
  final ioFiles = <File>[];

  final fsFiles = await fs.copyDirectoryListFiles(fs_io.wrapIoDirectory(src),
      options: options);
  for (final fsFile in fsFiles) {
    ioFiles.add(fs_io.unwrapIoFile(fsFile));
  }
  return ioFiles;
}
