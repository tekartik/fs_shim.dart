library;

import 'dart:io' as io;

import 'fs.dart' as fs;

import 'src/io/fs_io.dart' show fileSystemIo;
import 'src/io/io_directory.dart';
import 'src/io/io_file.dart';
import 'src/io/io_file_stat.dart';
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
        File,
        FileSystemEntity,
        Directory,
        Link,
        FileSystem,
        FileSystemEntityType,
        FileSystemException,
        FileStat,
        FileMode,
        OSError;

export 'src/io/fs_io.dart' show fileSystemIo;

@Deprecated('Use fileSystemIo instead')
// ignore: public_member_api_docs
fs.FileSystem get ioFileSystem => fileSystemIo;

/// Wrap IO file.
fs.File wrapIoFile(io.File ioFile) => FileImpl.io(ioFile);

/// Unwrap IO file.
io.File unwrapIoFile(fs.File file) => (file as FileImpl).ioFile!;

/// Wrap IO directory.
fs.Directory wrapIoDirectory(io.Directory ioDirectory) =>
    DirectoryImpl.io(ioDirectory);

/// Unwrap IO directory.
io.Directory /*!*/ unwrapIoDirectory(fs.Directory dir) =>
    (dir as DirectoryImpl).ioDir!;

/// Wraps IO link.
fs.Link wrapIoLink(io.Link ioLink) => LinkImpl.io(ioLink);

/// Unwraps IO link.
io.Link /*!*/ unwrapIoLink(fs.Link dir) => (dir as LinkImpl).ioLink!;

/// Wraps IO FileSystemException.
fs.FileSystemException wrapIoFileSystemException(
  io.FileSystemException ioFileSystemException,
) => FileSystemExceptionImpl.io(ioFileSystemException);

/// Unwraps IO FileSystemException.
io.FileSystemException unwrapIoFileSystemException(
  fs.FileSystemException fileSystemException,
) => (fileSystemException as FileSystemExceptionImpl).ioFileSystemException;

/// Wraps IO OS Error.
fs.OSError? /*!*/
/*!*/ wrapIoOSError(io.OSError? /*!*/ ioOSError) => OSErrorImpl.io(ioOSError);

/// Unwraps IO OS Error.
io.OSError? /*!*/ unwrapIoOSError(fs.OSError? /*!*/ osError) =>
    (osError as OSErrorImpl?)?.ioOSError;

/// Wraps IO FileStat.
fs.FileStat wrapIoFileStat(io.FileStat ioFileStat) =>
    FileStatImpl.io(ioFileStat);

/// Unwraps IO FileStat.
io.FileStat unwrapIoFileStat(fs.FileStat fileStat) =>
    (fileStat as FileStatImpl).ioFileStat;

/// Wraps IO FileMode.
fs.FileMode wrapIoFileMode(io.FileMode ioFileMode) =>
    wrapIoFileModeImpl(ioFileMode);

/// Unwraps IO FileMode.
io.FileMode unwrapIoFileMode(fs.FileMode fileMode) =>
    unwrapIoFileModeImpl(fileMode);

/// Wraps IO FileSystemEntityType.
fs.FileSystemEntityType wrapIoFileSystemEntityType(
  io.FileSystemEntityType ioFileSystemEntityType,
) => wrapIoFileSystemEntityTypeImpl(ioFileSystemEntityType);

/// Unwraps IO FileSystemEntityType.
io.FileSystemEntityType unwrapIoFileSystemEntityType(
  fs.FileSystemEntityType fileSystemEntityType,
) => unwrapIoFileSystemEntityTypeImpl(fileSystemEntityType);
