library;

import 'package:fs_shim/src/common/import.dart';

import 'src/utils_impl.dart';
import 'src/utils_impl.dart' as utils_impl;

export 'src/utils_impl.dart'
    show
        fsCopyDebug,
        fsDeleteDebug,
        fsTopEntity,
        // should deprecate
        TopCopy,
        // should deprecate
        TopSourceNode,
        // should deprecate
        CopyEntity,
        // should deprecate
        ChildCopy,
        // should deprecate
        TopEntity,
        // should deprecate
        topEntityPath;

/// Copy a directory
///
/// returns dst directory
///
Future<Directory> copyDirectory(
  Directory src,
  Directory? dst, {
  CopyOptions? options,
}) => utils_impl.copyDirectory(src, dst, options: options);

/// Copy a file.
Future<File> copyFile(File src, File dst, {CopyOptions? options}) =>
    utils_impl.copyFile(src, dst, options: options);

///
/// List the files to be copied
///
Future<List<File>> copyDirectoryListFiles(
  Directory src, {
  CopyOptions? options,
}) => utils_impl.copyDirectoryListFiles(src, options: options);
// Future<Link> copyLink(Link src, Link dst, {CopyOptions options}) => _impl.copyLink(src, dst, options: options);

/// Copy a file or a directory
@Deprecated('User copyDirectory or copyFile')
Future<FileSystemEntity> copyFileSystemEntity(
  FileSystemEntity src,
  FileSystemEntity dst, {
  CopyOptions? options,
}) {
  options ??= CopyOptions(); // old behavior will change!
  return utils_impl.copyFileSystemEntity(src, dst, options: options);
}

/// Copy options.
///
/// If [include] is specified, only files specified will be copied.
/// for "include", use trailing / to specify a directoy
class CopyOptions extends Object
    with
        OptionsDeleteMixin,
        OptionsRecursiveMixin,
        OptionsExcludeMixin,
        OptionsFollowLinksMixin,
        OptionsIncludeMixin {
  //final bool delete; // delete destination first
  /// Check size and copy if newer.
  bool checkSizeAndModifiedDate;

  /// Try to link file first.
  bool tryToLinkFile;

  /// Try to link dir first (not supported)
  bool tryToLinkDir; // not supported yet

  /// Verbose
  final bool verbose;

  /// Copy options.
  CopyOptions({
    bool recursive = false,
    this.checkSizeAndModifiedDate = false,
    this.tryToLinkFile = false,
    this.tryToLinkDir = false,
    bool followLinks = true,
    bool delete = false,
    List<String>? include,
    List<String>? exclude,
    bool? verbose,
  }) : verbose = verbose ?? false {
    this.recursive = recursive;
    this.delete = delete;
    this.exclude = exclude;
    this.include = include;
    this.followLinks = followLinks;
  }

  /// Clone options.
  CopyOptions get clone => copyWith();

  /// Copy with, cloning with optional override
  CopyOptions copyWith({
    bool? recursive,
    bool? checkSizeAndModifiedDate,
    bool? tryToLinkFile,
    bool? tryToLinkDir,
    bool? followLinks,
    bool? delete,
    List<String>? include,
    List<String>? exclude,
    bool? verbose,
  }) => CopyOptions(
    recursive: recursive ?? this.recursive,
    checkSizeAndModifiedDate:
        checkSizeAndModifiedDate ?? this.checkSizeAndModifiedDate,
    tryToLinkFile: tryToLinkFile ?? this.tryToLinkFile,
    tryToLinkDir: tryToLinkDir ?? this.tryToLinkDir,
    followLinks: followLinks ?? this.followLinks,
    delete: delete ?? this.delete,
    include: include ?? this.include,
    exclude: exclude ?? this.exclude,
    verbose: verbose ?? this.verbose,
  );
}

/// Only copy if date is new.
CopyOptions get copyNewerOptions => CopyOptions(checkSizeAndModifiedDate: true);

/// Only link (or copy if not possible) new files.
CopyOptions get recursiveLinkOrCopyNewerOptions => CopyOptions(
  recursive: true,
  checkSizeAndModifiedDate: true,
  tryToLinkFile: true,
);

/// Default clone tries to link first.
CopyOptions get defaultCloneOptions => CopyOptions(tryToLinkFile: true);

/// Default copy is recursive.
CopyOptions get defaultCopyOptions => CopyOptions()..recursive = true;

/// Delete a directory recursively.
Future deleteDirectory(Directory dir, {DeleteOptions? options}) =>
    utils_impl.deleteDirectory(dir, options: options);

/// Delete a file recursively.
Future deleteFile(File file, {DeleteOptions? options}) =>
    utils_impl.deleteFile(file, options: options);

/// Create options.
class CreateOptions extends Object
    with OptionsDeleteMixin, OptionsRecursiveMixin {
  /// Clone the options.
  CreateOptions get clone => CreateOptions()
    ..delete = delete
    ..recursive = recursive;
}

/// Default recursive create options.
final CreateOptions defaultRecursiveCreateOptions = CreateOptions()
  ..recursive = true;

/// recursive by default
final CreateOptions defaultCreateOptions = defaultRecursiveCreateOptions;

/// Create a directory recursively
Future<Directory> createDirectory(Directory dir, {CreateOptions? options}) =>
    utils_impl.createDirectory(dir, options: options);

/// Create a directory recursively
Future<File> createFile(File file, {CreateOptions? options}) =>
    utils_impl.createFile(file, options: options);

/// Delete options.
class DeleteOptions extends Object
    with OptionsRecursiveMixin, OptionsCreateMixin, OptionsFollowLinksMixin {
  @override
  String toString() {
    final map = <String, Object?>{};
    if (recursive) {
      map['recursive'] = recursive;
    }
    return map.toString();
  }

  /// Create new options
  DeleteOptions get clone => DeleteOptions()
    ..recursive = recursive
    ..followLinks = followLinks
    ..create = create;
}

/// Delete recursively options
final DeleteOptions defaultRecursiveDeleteOptions = DeleteOptions()
  ..recursive = true;

/// Delete options default, delete recursively.
final DeleteOptions defaultDeleteOptions = defaultRecursiveDeleteOptions;
