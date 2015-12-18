library fs_shim.utils.copy;

import 'dart:async';
//import 'package:logging/logging.dart' as log;
//import 'package:path/path.dart';
//import 'package:path/path.dart' as _path;
import '../fs.dart';
import '../src/common/import.dart';
import 'src/utils_impl.dart';
import 'src/utils_impl.dart' as _impl;
// SOON not exported any more
export 'src/utils_impl.dart'
    show
        fsCopyDebug,
        fsDeleteDebug,
        fsTopEntity,
        TopCopy,
        CopyEntity,
        ChildCopy,
        TopEntity,
        topEntityPath;

/// Main entry point
///
/// returns dst directory
///
Future<Directory> copyDirectory(Directory src, Directory dst,
        {CopyOptions options}) =>
    _impl.copyDirectory(src, dst, options: options);

Future<File> copyFile(File src, File dst, {CopyOptions options}) =>
    _impl.copyFile(src, dst, options: options);

// Future<Link> copyLink(Link src, Link dst, {CopyOptions options}) => _impl.copyLink(src, dst, options: options);

// Copy a file or a directory
@deprecated
Future<FileSystemEntity> copyFileSystemEntity(
    FileSystemEntity src, FileSystemEntity dst,
    {CopyOptions options}) {
  options ??= new CopyOptions(); // old behavior will change!
  return _impl.copyFileSystemEntity(src, dst, options: options);
}

class CopyOptions extends Object
    with
        OptionsDeleteMixin,
        OptionsRecursiveMixin,
        OptionsExcludeMixin,
        OptionsFollowLinksMixin {
  //final bool delete; // delete destination first
  bool checkSizeAndModifiedDate;
  bool tryToLinkFile;
  bool tryToLinkDir; // not supported yet

  CopyOptions(
      {bool recursive: false,
      this.checkSizeAndModifiedDate: false,
      this.tryToLinkFile: false,
      this.tryToLinkDir: false,
      bool followLinks: true,
      bool delete: false,
      List<String> exclude}) {
    this.recursive = recursive;
    this.delete = delete;
    this.exclude = exclude;
    this.followLinks = followLinks;
  }

  CopyOptions get clone => new CopyOptions()
    ..recursive = recursive
    ..checkSizeAndModifiedDate = checkSizeAndModifiedDate
    ..tryToLinkFile = tryToLinkFile
    ..tryToLinkDir = tryToLinkDir
    ..followLinks = followLinks
    ..delete = delete
    ..exclude = exclude;
}

CopyOptions copyNewerOptions = new CopyOptions(checkSizeAndModifiedDate: true);
CopyOptions recursiveLinkOrCopyNewerOptions = new CopyOptions(
    recursive: true, checkSizeAndModifiedDate: true, tryToLinkFile: true);
CopyOptions defaultCloneOptions = new CopyOptions(tryToLinkFile: true);
CopyOptions defaultCopyOptions = new CopyOptions()..recursive = true;

/// Delete a directory recursively
Future deleteDirectory(Directory dir, {DeleteOptions options}) =>
    _impl.deleteDirectory(dir, options: options);

/// Delete a file recursively
Future deleteFile(File file, {DeleteOptions options}) =>
    _impl.deleteFile(file, options: options);

class CreateOptions extends Object
    with OptionsDeleteMixin, OptionsRecursiveMixin {
  CreateOptions get clone => new CreateOptions()
    ..delete = delete
    ..recursive = recursive;
}

final CreateOptions defaultRecursiveCreateOptions = new CreateOptions()
  ..recursive = true;

/// recursive by default
final CreateOptions defaultCreateOptions = defaultRecursiveCreateOptions;

/// Create a directory recursively
Future<Directory> createDirectory(Directory dir, {CreateOptions options}) =>
    _impl.createDirectory(dir, options: options);

/// Create a directory recursively
Future<File> createFile(File file, {CreateOptions options}) =>
    _impl.createFile(file, options: options);

class DeleteOptions extends Object
    with OptionsRecursiveMixin, OptionsCreateMixin, OptionsFollowLinksMixin {
  String toString() {
    Map map = {};
    if (recursive) {
      map['recursive'] = recursive;
    }
    return map.toString();
  }

  DeleteOptions get clone => new DeleteOptions()
    ..recursive = recursive
    ..followLinks = followLinks
    ..create = create;
}

final DeleteOptions defaultRecursiveDeleteOptions = new DeleteOptions()
  ..recursive = true;
final DeleteOptions defaultDeleteOptions = defaultRecursiveDeleteOptions;
