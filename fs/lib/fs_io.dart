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
import 'src/io/fs_io.dart';
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
export 'src/io/fs_io.dart' show fileSystemIo;

@Deprecated('Use fileSystemIo instead')
// ignore: public_member_api_docs
FileSystem get ioFileSystem => fileSystemIo;

/// File.
abstract class File implements fs.File, FileSystemEntity {
  /// Creates a file entity.
  factory File(String path) => FileImpl(path);
}

/// Wrap IO file.
File wrapIoFile(io.File ioFile) => FileImpl.io(ioFile);

/// Unwrap IO file.
io.File unwrapIoFile(fs.File file) => (file as FileImpl).ioFile!;

/// Directory.
abstract class Directory implements fs.Directory, FileSystemEntity {
  /// Creates a directory entity.
  factory Directory(String path) => DirectoryImpl(path);

  @override
  Stream<FileSystemEntity> list(
      {bool recursive = false, bool followLinks = true});

  ///
  /// Creates a directory object pointing to the current working
  /// directory.
  ///
  static Directory get current => currentDirectory;
}

/// Wrap IO directory.
Directory wrapIoDirectory(io.Directory ioDirectory) =>
    DirectoryImpl.io(ioDirectory);

/// Unwrap IO directory.
io.Directory /*!*/ unwrapIoDirectory(fs.Directory dir) =>
    (dir as DirectoryImpl).ioDir!;

/// Link
abstract class Link extends fs.Link implements FileSystemEntity {
  /// Creates a link entity.
  factory Link(String path) => LinkImpl(path);
}

/// Wraps IO link.
Link wrapIoLink(io.Link ioLink) => LinkImpl.io(ioLink);

/// Unwraps IO link.
io.Link /*!*/ unwrapIoLink(Link dir) => (dir as LinkImpl).ioLink!;

/// File System Entity
abstract class FileSystemEntity extends fs.FileSystemEntity {
  ///
  /// Checks if type(path, followLinks: false) returns
  /// FileSystemEntityType.LINK.
  ///
  static Future<bool> isLink(String path) => fileSystemIo.isLink(path);

  ///
  /// Checks if type(path) returns FileSystemEntityType.FILE.
  ///

  ///
  /// Checks if type(path) returns FileSystemEntityType.DIRECTORY.
  ///
  static Future<bool> isDirectory(String path) =>
      fileSystemIo.isDirectory(path);

  ///
  /// Checks if type(path) returns FileSystemEntityType.FILE.
  ///
  static Future<bool> isFile(String path) => fileSystemIo.isFile(path);

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
          {bool followLinks = true}) =>
      fileSystemIo.type(path, followLinks: followLinks);
}

/// Wraps IO FileSystemException.
FileSystemException wrapIoFileSystemException(
        io.FileSystemException ioFileSystemException) =>
    FileSystemExceptionImpl.io(ioFileSystemException);

/// Unwraps IO FileSystemException.
io.FileSystemException unwrapIoFileSystemException(
        FileSystemException fileSystemException) =>
    (fileSystemException as FileSystemExceptionImpl).ioFileSystemException;

/// Wraps IO OS Error.
OSError? /*!*/ /*!*/ wrapIoOSError(io.OSError? /*!*/ ioOSError) =>
    OSErrorImpl.io(ioOSError);

/// Unwraps IO OS Error.
io.OSError? /*!*/ unwrapIoOSError(OSError? /*!*/ osError) =>
    (osError as OSErrorImpl?)?.ioOSError;

/// Wraps IO FileStat.
FileStat wrapIoFileStat(io.FileStat ioFileStat) => FileStatImpl.io(ioFileStat);

/// Unwraps IO FileStat.
io.FileStat unwrapIoFileStat(FileStat fileStat) =>
    (fileStat as FileStatImpl).ioFileStat;

/// Wraps IO FileMode.
FileMode wrapIoFileMode(io.FileMode ioFileMode) =>
    wrapIoFileModeImpl(ioFileMode);

/// Unwraps IO FileMode.
io.FileMode unwrapIoFileMode(FileMode fileMode) =>
    unwrapIoFileModeImpl(fileMode);

/// Wraps IO FileSystemEntityType.
FileSystemEntityType wrapIoFileSystemEntityType(
        io.FileSystemEntityType ioFileSystemEntityType) =>
    wrapIoFileSystemEntityTypeImpl(ioFileSystemEntityType);

/// Unwraps IO FileSystemEntityType.
io.FileSystemEntityType unwrapIoFileSystemEntityType(
        FileSystemEntityType fileSystemEntityType) =>
    unwrapIoFileSystemEntityTypeImpl(fileSystemEntityType);
