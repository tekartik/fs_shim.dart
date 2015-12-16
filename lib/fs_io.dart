library fs_shim.fs_io;

import 'fs.dart' as fs;
import 'dart:io' as io;
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
import 'src/io/io_file_stat.dart';
import 'src/io/io_file_system_exception.dart';

final fs.FileSystem ioFileSystem = new IoFileSystem();

/// File system
abstract class IoFileSystem extends fs.FileSystem {
  factory IoFileSystem() => new IoFileSystemImpl();
}

/// File
abstract class File extends fs.File {
  factory File(String path) => new FileImpl(path);
}

// Wrap/unwrap
File wrapIoFile(io.File ioFile) => new FileImpl.io(ioFile);
io.File unwrapIoFile(File file) => (file as FileImpl).ioFile;

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

// Wrap/unwrap
Directory wrapIoDirectory(io.Directory ioDirectory) =>
    new DirectoryImpl.io(ioDirectory);
io.Directory unwrapIoDirectory(Directory dir) => (dir as DirectoryImpl).ioDir;

/// Link
abstract class Link extends fs.Link {
  factory Link(String path) => new LinkImpl(path);
}

// Wrap/unwrap
Link wrapIoLink(io.Link ioLink) => new LinkImpl.io(ioLink);
io.Link unwrapIoLink(Link dir) => (dir as LinkImpl).ioLink;

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

  ///
  /// Finds the type of file system object that a path points to. Returns
  /// a [:Future<FileSystemEntityType>:] that completes with the result.
  ///
  /// [FileSystemEntityType] has the constant instances FILE, DIRECTORY,
  /// LINK, and NOT_FOUND.  [type] will return LINK only if the optional
  /// named argument [followLinks] is false, and [path] points to a link.
  /// If the path does not point to a file system object, or any other error
  /// occurs in looking up the path, NOT_FOUND is returned.  The only
  /// error or exception that may be put on the returned future is ArgumentError,
  /// caused by passing the wrong type of arguments to the function.
  ///
  static Future<FileSystemEntityType> type(String path,
          {bool followLinks: true}) =>
      ioFileSystem.type(path, followLinks: followLinks);
}

// OSError

// FileStat Wrap/unwrap
fs.FileStat wrapIoFileStat(io.FileStat ioFileStat) =>
    new FileStatImpl.io(ioFileStat);
io.FileStat unwrapIoFileStat(fs.FileStat fileStat) =>
    (fileStat as FileStatImpl).ioFileStat;
