library fs_shim.fs_io;

import 'dart:async';
import 'dart:io' as io;

import 'fs.dart' as fs show File, Directory, Link, FileSystemEntity;
import 'fs.dart'
    show
    FileSystem,
    FileSystemEntityType,
    FileSystemException,
    FileStat,
    FileMode,
    OSError;
import 'src/io/io_directory.dart';
import 'src/io/io_file.dart';
import 'src/io/io_file_stat.dart';
import 'src/io/io_file_system.dart';
import 'src/io/io_file_system_exception.dart';
import 'src/io/io_fs.dart';
import 'src/io/io_link.dart';

export 'dart:io'
    hide
        File,
        Directory,
        Link,
        FileSystemEntity,
        FileSystemEntityType,
        FileMode,
        FileSystemException,
        FileStat,
        OSError;

export 'fs.dart'
    show
        FileSystem,
        FileSystemEntityType,
        FileSystemException,
        FileStat,
        FileMode,
        OSError;

final FileSystem ioFileSystem = new IoFileSystem();

/// File system
abstract class IoFileSystem extends FileSystem {
  factory IoFileSystem() => new IoFileSystemImpl();
}

/// File
abstract class File implements fs.File, FileSystemEntity {
  factory File(String path) => new FileImpl(path);
}

// Wrap/unwrap
File wrapIoFile(io.File ioFile) => new FileImpl.io(ioFile);

io.File unwrapIoFile(fs.File file) => (file as FileImpl).ioFile;

/// Directory
abstract class Directory implements fs.Directory, FileSystemEntity {
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

io.Directory unwrapIoDirectory(fs.Directory dir) =>
    (dir as DirectoryImpl).ioDir;

/// Link
abstract class Link extends fs.Link implements FileSystemEntity {
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

// FileSystemException Wrap/unwrap
FileSystemException wrapIoFileSystemException(
        io.FileSystemException ioFileSystemException) =>
    new FileSystemExceptionImpl.io(ioFileSystemException);
io.FileSystemException unwrapIoFileSystemException(
        FileSystemException fileSystemException) =>
    (fileSystemException as FileSystemExceptionImpl).ioFileSystemException;

// OSError Wrap/unwrap
OSError wrapIoOSError(io.OSError ioOSError) => new OSErrorImpl.io(ioOSError);
io.OSError unwrapIoOSError(OSError osError) =>
    (osError as OSErrorImpl).ioOSError;

// FileStat Wrap/unwrap
FileStat wrapIoFileStat(io.FileStat ioFileStat) =>
    new FileStatImpl.io(ioFileStat);
io.FileStat unwrapIoFileStat(FileStat fileStat) =>
    (fileStat as FileStatImpl).ioFileStat;

// FileMode Wrap/unwrap
FileMode wrapIoFileMode(io.FileMode ioFileMode) =>
    wrapIofileModeImpl(ioFileMode);
io.FileMode unwrapIoFileMode(FileMode fileMode) =>
    unwrapIofileModeImpl(fileMode);

// FileSystemEntityType Wrap/unwrap
FileSystemEntityType wrapIoFileSystemEntityType(
        io.FileSystemEntityType ioFileSystemEntityType) =>
    wrapIoFileSystemEntityTypeImpl(ioFileSystemEntityType);
io.FileSystemEntityType unwrapIoFileSystemEntityType(
        FileSystemEntityType fileSystemEntityType) =>
    unwrapIoFileSystemEntityTypeImpl(fileSystemEntityType);
