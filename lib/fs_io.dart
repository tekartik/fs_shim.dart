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
export 'fs.dart'
    show FileSystem, FileSystemEntityType, FileSystemException, FileStat;
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

  ///
  /// Creates a directory object pointing to the current working
  /// directory.
  ///
  static Directory get current => currentDirectory;
}

/// Link
abstract class Link extends fs.Link {
  factory Link(String path) => new LinkImpl(path);
}

/// File System Entity
abstract class FileSystemEntity extends fs.FileSystemEntity {
  ///
  /// Checks if type(path, followLinks: false) returns
  /// FileSystemEntityType.LINK.
  ///
  static Future<bool> isLink(String path) => ioFileSystem.isLink(path);

  ///
  /// Checks if type(path) returns FileSystemEntityType.FILE.
  ///

  ///
  /// Checks if type(path) returns FileSystemEntityType.DIRECTORY.
  ///
  static Future<bool> isDirectory(String path) =>
      ioFileSystem.isDirectory(path);

  ///
  /// Checks if type(path) returns FileSystemEntityType.FILE.
  ///
  static Future<bool> isFile(String path) => ioFileSystem.isFile(path);
}
