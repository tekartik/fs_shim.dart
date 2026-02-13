// Copyright (c) 2015, Alexandre Roux. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

/// The fs_shim library.
///
/// This is an awesome library. More dartdocs go here.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:fs_shim/fs_shim.dart';
import 'package:path/path.dart' as p;

import 'fs.dart' as fs;

/// File system extension
/// - [fs.Directory.tryCreate].
export 'src/common/fs_directory.dart' show FsShimDirectoryExtension;

/// File system sandboxing
export 'src/common/fs_extension.dart' show FsShimFileSystemExtension;

/// File system entity parent, i.e. directory or file system.
export 'src/common/fs_file_system_entity_parent.dart'
    show FileSystemEntityParent;

/// File system sandboxing
export 'src/common/fs_sandbox.dart' show FsShimSandboxedFileSystem;
export 'src/random_access_file.dart' show RandomAccessFile;

/// A reference to an entity on the file system, such as a file or directory.
///
/// `FileSystemEntity` is an abstract class, with subclasses [File],
/// [Directory], and [Link]. Most of the methods in this class are abstract and
/// are implemented in the subclasses.
abstract class FileSystemEntity {
  /// The path of the entity.
  String get path;

  /// Checks whether the file system entity with this path exists.
  ///
  /// Returns a `Future<bool>` that completes with the result.
  ///
  /// Since `FileSystemEntity` is abstract, every `FileSystemEntity` object
  /// is actually an instance of one of the subclasses [File],
  /// [Directory], and [Link]. Calling [exists] on an instance of one
  /// of these subclasses checks whether the object exists in the file
  /// system object exists and is of the correct type (file, directory,
  /// or link). To check whether a path points to an object on the
  /// file system, regardless of the object's type, use the [FileSystem.type]
  /// static method.
  Future<bool> exists();

  /// Deletes this [FileSystemEntity].
  ///
  /// If the [FileSystemEntity] is a directory, and if [recursive] is false,
  /// the directory must be empty. Otherwise, if [recursive] is true, the
  /// directory and all sub-directories and files in the directories are
  /// deleted. Links are not followed when deleting recursively. Only the link
  /// is deleted, not its target.
  ///
  /// If [recursive] is true, the [FileSystemEntity] is deleted even if the type
  /// of the [FileSystemEntity] doesn't match the content of the file system.
  /// This behavior allows [delete] to be used to unconditionally delete any file
  /// system object.
  ///
  /// Returns a `Future<FileSystemEntity>` that completes with this
  /// [FileSystemEntity] when the deletion is done. If the [FileSystemEntity]
  /// cannot be deleted, the future completes with an exception.
  Future<FileSystemEntity> delete({bool recursive = false});

  /// Renames this file system entity.
  ///
  /// Returns a `Future<FileSystemEntity>` that completes with a
  /// [FileSystemEntity] instance for the renamed file system entity.
  ///
  /// If [newPath] identifies an existing entity of the same type, that entity
  /// is replaced. If [newPath] identifies an existing entity of a different
  /// type, the operation fails and the future completes with an exception.
  Future<FileSystemEntity> rename(String newPath);

  /// Returns a `bool` indicating whether this object's path is absolute.
  ///
  /// On Windows, a path is absolute if it starts with `\\` or a drive letter
  /// between `a` and `z` (upper or lower case) followed by `:\` or `:/`.
  /// On non-Windows, a path is absolute if it starts with `/`.
  bool get isAbsolute;

  /// Calls the operating system's `stat()` function on the [path] of this
  /// [FileSystemEntity].
  ///
  /// Identical to `FileStat.stat(this.path)`.
  ///
  /// Returns a `Future<FileStat>` object containing the data returned by
  /// `stat()`.
  ///
  /// If the call fails, completes the future with a [FileStat] object
  /// with `.type` set to `FileSystemEntityType.notFound` and the other fields
  /// invalid.
  Future<FileStat> stat();

  /// The directory containing `this`.
  ///
  /// If `this` is a root directory, returns `this`.
  Directory get parent;

  /// The file system for this entity.
  FileSystem get fs;

  /// Checks if `type(path, followLinks: false)` returns
  /// `FileSystemEntityType.link`.
  static Future<bool> isLink(String path) => fileSystemDefault.isLink(path);

  /// Checks if `type(path)` returns `FileSystemEntityType.directory`.
  static Future<bool> isDirectory(String path) =>
      fileSystemDefault.isDirectory(path);

  /// Checks if `type(path)` returns `FileSystemEntityType.file`.
  static Future<bool> isFile(String path) => fileSystemDefault.isFile(path);

  /// Finds the type of file system object that a path points to.
  ///
  /// Returns a `Future<FileSystemEntityType>` that completes with the result.
  ///
  /// `FileSystemEntityType` has the constant instances `file`, `directory`,
  /// `link`, and `notFound`. [type] will return `link` only if the optional
  /// named argument [followLinks] is false, and [path] points to a link.
  /// If the path does not point to a file system object, or any other error
  /// occurs in looking up the path, `notFound` is returned. The only
  /// error or exception that may be put on the returned future is
  /// `ArgumentError`, caused by passing the wrong type of arguments to the
  /// function.
  static Future<FileSystemEntityType> type(
    String path, {
    bool followLinks = true,
  }) => fileSystemDefault.type(path, followLinks: followLinks);
}

/// The mode in which a file is opened.
///
/// The [FileMode] is used by [File.open] and [File.openSync] to specify
/// whether a file is opened for reading, writing, or appending.
class FileMode {
  const FileMode._internal(this._mode);

  /// The mode for opening a file for reading only.
  static const read = FileMode._internal(0);

  /// The mode for opening a file for writing.
  ///
  /// The file is overwritten if it already exists. The file is created if it
  /// does not already exist.
  static const write = FileMode._internal(1);

  /// The mode for opening a file for writing to the end of it.
  ///
  /// The file is created if it does not already exist.
  static const append = FileMode._internal(2);

  final int _mode;

  /// The mode value.
  int get mode => _mode;

  @override
  String toString() {
    switch (this) {
      case write:
        return 'FileMode.write';
      case read:
        return 'FileMode.read';
      case append:
        return 'FileMode.append';
    }
    return 'FileMode($mode)';
  }
}

/// Information about a file system object.
///
/// `FileStat` objects are returned from [File.stat], [Directory.stat],
/// [Link.stat], and [FileSystemEntity.stat].
abstract class FileStat {
  /// The mode is not supported on all file systems.
  static const modeNotSupported = -1;

  /// The time of the last change to the data of the file system object.
  DateTime get modified;

  /// The type of the object (file, directory, or link).
  ///
  /// If the call to `stat()` fails, the type of the returned object is
  /// `FileSystemEntityType.notFound`.
  FileSystemEntityType? get type;

  /// The size of the file system object.
  int get size;

  /// The mode of the file system object.
  ///
  /// This is a bit field with the same values as the `st_mode` field of the
  /// `stat` structure on Unix-like systems. The values can be accessed using
  /// the `mode*` constants in this class.
  ///
  /// On Windows, only the `modeType` and `modeWritable` bits are set.
  int get mode;
}

/// A reference to a file on the file system.
abstract class File extends FileSystemEntity {
  /// Creates a [File] object.
  ///
  /// If [path] is a relative path, it will be interpreted relative to the
  /// current working directory (see [Directory.current]), when used.
  ///
  /// If [path] is an absolute path, it will be immune to changes to the
  /// current working directory.
  factory File(String path) => fileSystemDefault.file(path);

  /// Create the file.
  ///
  /// Returns a `Future<File>` that completes with the file when it has been
  /// created.
  ///
  /// If [recursive] is false, the default, the file is created only if all
  /// directories in the path exist. If [recursive] is true, all non-existing
  /// path components are created.
  ///
  /// Existing files are left untouched by [create]. Calling [create] on an
  /// existing file might fail if there are restrictive permissions on the file.
  ///
  /// Completes the future with a [FileSystemException] if the operation fails.
  Future<File> create({bool recursive = false});

  /// Creates a new independent [StreamSink] for the file.
  ///
  /// The [StreamSink] must be closed when no longer used, to free system
  /// resources.
  ///
  /// An [StreamSink] for a file can be opened in two modes:
  ///
  /// * [FileMode.write]: truncates the file to length zero.
  /// * [FileMode.append]: sets the initial write position to the end of the
  ///   file.
  ///
  /// When writing strings through the returned [StreamSink] the encoding
  /// specified using [encoding] will be used. The returned [StreamSink] has an
  /// `encoding` property which can be changed after the [StreamSink] has been
  /// created.
  StreamSink<List<int>> openWrite({
    FileMode mode = FileMode.write,
    Encoding encoding = utf8,
  });

  /// Creates a new independent [Stream] for the contents of this file.
  ///
  /// If [start] is present, the file will be read from byte-offset [start].
  /// Otherwise from the beginning (index 0).
  ///
  /// If [end] is present, only up to byte-index [end] will be read. Otherwise,
  /// until end of file.
  ///
  /// In order to make sure that system resources are freed, the stream must be
  /// read to completion or the subscription on the stream must be cancelled.
  Stream<Uint8List> openRead([int? start, int? end]);

  /// Opens the file for random access operations.
  ///
  /// Returns a `Future<RandomAccessFile>` that completes with the opened
  /// random access file. [RandomAccessFile]s must be closed using the
  /// [RandomAccessFile.close] method.
  ///
  /// Files can be opened in three modes:
  ///
  /// * [FileMode.read]: open the file for reading.
  ///
  /// * [FileMode.write]: open the file for both reading and writing and
  /// truncate the file to length zero. If the file does not exist the
  /// file is created.
  ///
  /// * [FileMode.append]: same as [FileMode.write] except that the file is
  /// not truncated.
  ///
  /// Throws a [FileSystemException] if the operation fails.
  Future<RandomAccessFile> open({FileMode mode = FileMode.read});

  /// Writes a list of bytes to a file.
  ///
  /// Opens the file, writes the list of bytes to it, and closes the file.
  /// Returns a `Future<File>` that completes with this [File] object once
  /// the entire operation has completed.
  ///
  /// By default [writeAsBytes] creates the file for writing and truncates the
  /// file if it already exists. In order to append the bytes to an existing
  /// file, pass [FileMode.append] as the optional mode parameter.
  ///
  /// If the argument [flush] is set to `true`, the data written will be
  /// flushed to the file system before the returned future completes.
  Future<File> writeAsBytes(
    Uint8List bytes, {
    FileMode mode = FileMode.write,
    bool flush = false,
  });

  /// Writes a string to a file.
  ///
  /// Opens the file, writes the string in the given encoding, and closes the
  /// file. Returns a `Future<File>` that completes with this [File] object
  /// once the entire operation has completed.
  ///
  /// By default [writeAsString] creates the file for writing and truncates the
  /// file if it already exists. In order to append the bytes to an existing
  /// file, pass [FileMode.append] as the optional mode parameter.
  ///
  /// If the argument [flush] is set to `true`, the data written will be
  /// flushed to the file system before the returned future completes.
  Future<File> writeAsString(
    String contents, {
    FileMode mode = FileMode.write,
    Encoding encoding = utf8,
    bool flush = false,
  });

  /// Reads the entire file contents as a list of bytes.
  ///
  /// Returns a `Future<List<int>>` that completes with the list of bytes that
  /// is the contents of the file.
  Future<Uint8List> readAsBytes();

  /// Reads the entire file contents as a string using the given [Encoding].
  ///
  /// Returns a `Future<String>` that completes with the string once the file
  /// contents has been read.
  Future<String> readAsString({Encoding encoding = utf8});

  /// Copies this file.
  ///
  /// Returns a `Future<File>` that completes with a [File] instance for the
  /// copied file.
  ///
  /// If [newPath] identifies an existing file, that file is replaced. If
  /// [newPath] identifies an existing directory, the operation fails and the
  /// future completes with an exception.
  Future<File> copy(String newPath);

  /// Returns a [File] instance whose path is the absolute path to `this`.
  ///
  /// The absolute path is computed by prefixing a relative path with the
  /// current working directory, and returning an absolute path unchanged.
  File get absolute;
}

/// A reference to a directory on the file system.
abstract class Directory extends FileSystemEntity
    implements FileSystemEntityParent {
  /// Creates a [Directory] object.
  ///
  /// If [path] is a relative path, it will be interpreted relative to the
  /// current working directory (see [Directory.current]), when used.
  ///
  /// If [path] is an absolute path, it will be immune to changes to the
  /// current working directory.
  factory Directory(String path) => fileSystemDefault.directory(path);

  /// Creates the directory with this name.
  ///
  /// If [recursive] is false, only the last directory in the path is
  /// created. If [recursive] is true, all non-existing path components
  /// are created. If the directory already exists nothing is done.
  ///
  /// Returns a `Future<Directory>` that completes with this
  /// directory once it has been created. If the directory cannot be
  /// created the future completes with an exception.
  Future<Directory> create({bool recursive = false});

  /// Returns a [Directory] instance whose path is the absolute path to `this`.
  ///
  /// The absolute path is computed by prefixing a relative path with the
  /// current working directory, and returning an absolute path unchanged.
  Directory get absolute;

  /// Lists the sub-directories and files of this [Directory].
  ///
  /// Optionally recurses into sub-directories.
  ///
  /// If [followLinks] is false, then any symbolic links found
  /// are reported as [Link] objects, rather than as directories or files,
  /// and are not recursed into.
  ///
  /// If [followLinks] is true, then working links are reported as
  /// directories or files, depending on
  /// their type, and links to directories are recursed into.
  /// Broken links are reported as [Link] objects.
  /// If a symbolic link makes a loop in the file system, then a recursive
  /// listing will not follow a link twice in the
  /// same recursive descent, but will report it as a [Link]
  /// the second time it is seen.
  ///
  /// The result is a stream of [FileSystemEntity] objects
  /// for the directories, files, and links.
  Stream<FileSystemEntity> list({
    bool recursive = false,
    bool followLinks = true,
  });

  /// A [Directory] object pointing to the current working directory.
  static Directory get current => fileSystemDefault.currentDirectory;
}

/// A reference to a link on the file system.
abstract class Link extends FileSystemEntity {
  /// Creates a [Link] object.
  factory Link(String path) => fileSystemDefault.link(path);

  /// Creates a symbolic link.
  ///
  /// Returns a `Future<Link>` that completes with the link when it has been
  /// created. If the link exists, the future will complete with an error.
  ///
  /// If [recursive] is false, the default, the link is created
  /// only if all directories in its path exist.
  /// If [recursive] is true, all non-existing path
  /// components are created. The directories in the path of [target] are
  /// not affected, unless they are also in [path].
  ///
  /// On the Windows platform, this will only work with directories, and the
  /// target directory must exist. The link will be created as a Junction.
  ///
  /// Only absolute links will be created, and relative paths to the target
  /// will be converted to absolute paths by joining them with the path of the
  /// directory the link is contained in.
  ///
  /// On other platforms, the posix symlink() call is used to make a symbolic
  /// link containing the string [target].  If [target] is a relative path,
  /// it will be interpreted relative to the directory containing the link.
  Future<Link> create(String target, {bool recursive = false});

  /// Returns a [Link] instance whose path is the absolute path to `this`.
  ///
  /// The absolute path is computed by prefixing a relative path with the
  /// current working directory, and returning an absolute path unchanged.
  Link get absolute;

  /// Gets the target of the link.
  ///
  /// Returns a future that completes with the path to the target.
  ///
  /// If the returned target is a relative path, it is relative to the
  /// directory containing the link.
  ///
  /// If the link does not exist, or is not a link, the future completes with
  /// a [FileSystemException].
  Future<String> target();

  @override
  Future<Link> rename(String newPath);
}

/// A sink for writing to a file.
abstract class FileSink implements StreamSink<List<int>>, StringSink {}

/// The type of an entity on the file system, such as a file, directory, or
/// link.
///
/// These constants are used by the [FileSystemEntity] class
/// to indicate the object's type.
class FileSystemEntityType {
  final int _type;

  const FileSystemEntityType._internal(this._type);

  /// File type.
  static const file = FileSystemEntityType._internal(0);

  /// Directory type.
  static const directory = FileSystemEntityType._internal(1);

  /// Link type.
  static const link = FileSystemEntityType._internal(2);

  /// The entity was not found.
  static const notFound = FileSystemEntityType._internal(3);

  @override
  String toString() => const ['FILE', 'DIRECTORY', 'LINK', 'NOT_FOUND'][_type];
}

/// An abstract file system.
abstract class FileSystem implements FileSystemEntityParent {
  /// Creates a [Directory] object.
  ///
  /// If [path] is a relative path, it will be interpreted relative to the
  /// current working directory (see [Directory.current]), when used.
  ///
  /// If [path] is an absolute path, it will be immune to changes to the
  /// current working directory.
  @override
  Directory directory(String path);

  /// Creates a [File] object.
  ///
  /// If [path] is a relative path, it will be interpreted relative to the
  /// current working directory (see [Directory.current]), when used.
  ///
  /// If [path] is an absolute path, it will be immune to changes to the
  /// current working directory.
  @override
  File file(String path);

  /// Creates a [Link] object.
  @override
  Link link(String path);

  /// Finds the type of file system object that a path points to.
  ///
  /// Returns a `Future<FileSystemEntityType>` that completes with the result.
  ///
  /// `FileSystemEntityType` has the constant instances `file`, `directory`,
  /// `link`, and `notFound`. [type] will return `link` only if the optional
  /// named argument [followLinks] is false, and [path] points to a link.
  /// If the path does not point to a file system object, or any other error
  /// occurs in looking up the path, `notFound` is returned. The only
  /// error or exception that may be put on the returned future is
  /// `ArgumentError`, caused by passing the wrong type of arguments to the
  /// function.
  Future<FileSystemEntityType> type(String path, {bool followLinks = true});

  /// Checks if `type(path)` returns `FileSystemEntityType.file`.
  Future<bool> isFile(String path);

  /// Checks if `type(path)` returns `FileSystemEntityType.directory`.
  Future<bool> isDirectory(String path);

  /// Checks if `type(path, followLinks: false)` returns
  /// `FileSystemEntityType.link`.
  Future<bool> isLink(String path);

  /// The name of the file system.
  String get name; // io or idb

  /// Whether the file system supports links.
  bool get supportsLink;

  /// Whether the file system supports file links.
  bool get supportsFileLink; // windows does not support file link

  /// Whether the file system supports random access.
  bool get supportsRandomAccess;

  /// The path context for this file system.
  p.Context get path;

  /// A [Directory] object pointing to the current working directory.
  Directory get currentDirectory;
}

/// An error from the operating system.
abstract class OSError {
  /// Constant used to indicate that no OS error code is available.
  static const int noErrorCode = -1;

  /// The error code from the operating system.
  ///
  /// This is a platform-specific value.
  ///
  /// If no error code is available, this is `noErrorCode`.
  int get errorCode;

  /// The error message from the operating system.
  ///
  /// This is a platform-specific value.
  ///
  /// If no error message is available, this is the empty string.
  String get message;
}

/// An exception holding information about a file system error.
abstract class FileSystemException {
  FileSystemException._();

  /// File not found.
  static const int statusNotFound = 2;

  /// File already exists.
  static const int statusAlreadyExists =
      17; // when creating a dir when it exists with another type (file)
  /// Not a directory.
  static const int statusNotADirectory =
      20; // when deleting a dir when it is a file
  /// Is a directory.
  static const int statusIsADirectory =
      21; // when creating a file and it is a dir
  /// Invalid argument.
  static const int statusInvalidArgument =
      22; // when acting on a link where the argument is not a link
  /// Directory not empty.
  static const int statusNotEmpty = 39; // when deleting a non empty directory
  /// Generic access error.
  static const int statusAccessError = 5; // for windows

  /// A message describing the error.
  ///
  /// This does not include any detailed information from the underlying OS
  /// error. Check [osError] for that information.
  String get message;

  /// A status code for the error.
  int? get status;

  /// The file system path on which the error occurred.
  ///
  /// Can be `null` if the exception does not relate directly to a file system
  /// path.
  String? get path;

  /// The underlying OS error.
  ///
  /// Can be `null` if the exception is not raised due to an OS error.
  OSError? get osError;
}
