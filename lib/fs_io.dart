library fs_shim.fs_io;

import 'fs.dart' as fs;
export 'dart:io'
    hide
        File,
        Directory,
        Link,
        FileSystemEntity,
        FileSystemEntityType,
        FileSystemException,
        FileStat;
export 'fs.dart' show FileSystem, FileSystemEntityType, FileSystemException, FileStat;
import 'dart:async';
import 'src/io/io_link.dart';
import 'src/io/io_directory.dart';
import 'src/io/io_fs.dart';
import 'src/io/io_file.dart';
import 'src/io/io_file_system.dart';

final fs.FileSystem ioFileSystem = new IoFileSystem();

/// File system
abstract class IoFileSystem extends fs.FileSystem {
  factory IoFileSystem() => new IoFileSystemImpl();
}

/// File
abstract class File extends fs.File {
  factory File(String path) => new FileImpl(path);
}

/// Directory
abstract class Directory extends fs.Directory {
  factory Directory(String path) => new DirectoryImpl(path);

  Stream<FileSystemEntity> list(
      {bool recursive: false, bool followLinks: true});
}

/// Link
abstract class Link extends fs.Link {
  factory Link(String path) => new LinkImpl(path);
}

/// File System Entity
abstract class FileSystemEntity extends fs.FileSystemEntity {
  // io helper
  static Future<bool> isDirectory(String path) =>
      ioFileSystem.isDirectory(path);

  // io helper
  static Future<bool> isFile(String path) => ioFileSystem.isFile(path);
}
