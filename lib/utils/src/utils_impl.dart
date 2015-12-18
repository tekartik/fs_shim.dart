library fs_shim.utils.src.utils_impl;

import 'dart:async';

//import 'package:logging/logging.dart' as log;
import 'package:path/path.dart';
//import 'package:path/path.dart' as _path;
import '../../fs.dart';
import '../glob.dart';
import '../../src/common/import.dart';
import '../copy.dart';

/*
bool _fsUtilsDebug = false;

bool get fsUtilsDebug => _fsUtilsDebug;

///
/// deprecated to prevent permanant use
///
/// Use:
///
///     fsCopyDebug = true;
///
/// for debugging only
///
@deprecated
set fsUtilsDebug(bool debug) => fsShimUtilsDebug = debug;

set fsShimUtilsDebug(bool debug) => _fsUtilsDebug = debug;
*/

bool _fsCopyDebug = false;
bool get fsCopyDebug => _fsCopyDebug;

///
/// deprecated to prevent permanant use
///
/// Use:
///
///     fsCopyDebug = true;
///
/// for debugging only
///
@deprecated
set fsCopyDebug(bool debug) => _fsCopyDebug = debug;

// should not be exported
List<Glob> globList(List<String> expressions) {
  List<Glob> globs = [];
  if (expressions != null) {
    for (String expression in expressions) {
      globs.add(new Glob(expression));
    }
  }
  return globs;
}

// for create/copy
class OptionsDeleteMixin {
  bool delete = false;
}

class OptionsCreateMixin {
  bool create = false;
}

class OptionsRecursiveMixin {
  bool recursive = true;
}

class OptionsExcludeMixin {
  List<String> exclude;

  // follow glob
  List<Glob> _excludeGlobs;

  List<Glob> get excludeGlobs {
    if (_excludeGlobs == null) {
      _excludeGlobs = globList(exclude);
    }
    return _excludeGlobs;
  }
}

/// Create a directory recursively
Future<Directory> createDirectory(Directory dir,
    {CreateOptions options}) async {
  options ??= defaultCreateOptions;
  if (options.delete) {
    await deleteDirectory(dir);
  }
  await dir.create(recursive: options.recursive);
  return dir;
}

/// Delete a directory recursively
Future deleteDirectory(Directory dir, {DeleteOptions options}) async {
  options ??= defaultDeleteOptions;

  try {
    await dir.delete(recursive: options.recursive);
  } catch (e) {
    if (e is FileSystemException) {
      if (e.status != FileSystemException.statusNotFound) {
        if (options.recursive == false &&
            e.status == FileSystemException.statusNotEmpty) {
          // ok
        } else {
          print('delete $dir failed $e');
        }
      }
    } else {
      print('delete $dir failed $e');
    }
  }
  if (options.create) {
    await dir.create(recursive: true);
  }
}

/// Delete a directory recursively
Future deleteFile(File file, {DeleteOptions options}) async {
  options ??= defaultDeleteOptions;
  try {
    await file.delete();
  } catch (e) {
    if (e is FileSystemException) {
      if (e.status != FileSystemException.statusNotFound) {
        print('delete $file failed $e');
      }
    } else {
      print('delete $file failed $e');
    }
  }
}

Future<Directory> copyDirectory(Directory src, Directory dst,
    {CopyOptions options}) async {
  options ??= defaultCopyOptions;
  if (await src.fs.isDirectory(src.path)) {
    await new TopCopy(
        new TopEntity(src.fs, src.path), new TopEntity(dst.fs, dst.path),
        options: options).run();
  } else {
    throw new ArgumentError('not a directory ($src)');
  }
  return dst;
}

Future<File> copyFile(File src, File dst, {CopyOptions options}) async {
  options ??= defaultCopyOptions;
  if (await src.fs.isFile(src.path)) {
    await copyFileSystemEntity_(src, dst, options: options);
  } else {
    throw new ArgumentError('not a file ($src)');
  }
  return dst;
}

Future<Link> copyLink(Link src, Link dst, {CopyOptions options}) async {
  if (await src.fs.isLink(src.path)) {
    await copyFileSystemEntity_(src, dst, options: options);
  } else {
    throw new ArgumentError('not a link ($src)');
  }
  return dst;
}

// Copy a file to its destination
Future<int> copyFileSystemEntity_(FileSystemEntity src, FileSystemEntity dst,
    {CopyOptions options}) async {
  options ??= defaultCopyOptions;
  return await copyFileSystemEntityImpl(src.fs, src.path, dst.fs, dst.path,
      options: options);
}

Future<int> copyFileSystemEntityImpl(FileSystem srcFileSystem, String srcPath,
    FileSystem dstFileSystem, String dstPath,
    {CopyOptions options}) async {
  options ??=
      new CopyOptions(); // old behavior - must be changed at an upper level
  int count = 0;

  if (fsCopyDebug) {
    print("$srcPath => $dstPath");
  }

  if (await srcFileSystem.isLink(srcPath) && (!options.followLinks)) {
    return 0;
  }

  // to ignore?
  if (options.excludeGlobs.isNotEmpty) {
    for (Glob glob in options.excludeGlobs) {
      if (glob.matches(srcPath)) {
        return 0;
      }
    }

    String name = posixPath(srcPath);

    //bool excluded = false;
    for (String matcher in options.exclude) {
      List<String> parts = posix.split(matcher);
      if (parts.length > 1) {
        if (name.contains(matcher)) {
          return 0;
        }
      }
    }
    /*
    // basic exclude
    if (options.exclude.contains(basename(srcPath))) {
      return 0;
    }
    posixPath
    */
  }

  if (await srcFileSystem.isDirectory(srcPath)) {
    Directory dstDirectory = dstFileSystem.newDirectory(dstPath);
    if (!await dstDirectory.exists()) {
      await dstDirectory.create(recursive: true);
      count++;
    }

    // recursive
    if (options.recursive) {
      Directory srcDirectory = srcFileSystem.newDirectory(srcPath);

      List<Future> futures = [];
      await srcDirectory
          .list(recursive: false, followLinks: options.followLinks)
          .listen((FileSystemEntity srcEntity) {
        String basename = srcFileSystem.pathContext.basename(srcEntity.path);
        futures.add(copyFileSystemEntityImpl(srcFileSystem, srcEntity.path,
            dstFileSystem, dstFileSystem.pathContext.join(dstPath, basename),
            options: options).then((int count_) {
          count += count_;
        }));
      }).asFuture();
      await Future.wait(futures);
    }
  } else if (await srcFileSystem.isFile(srcPath)) {
    File srcFile = srcFileSystem.newFile(srcPath);
    File dstFile = dstFileSystem.newFile(dstPath);

    // Try to link first
    // allow link if asked and on the same file system
    if (options.tryToLinkFile &&
        (srcFileSystem == dstFileSystem) &&
        srcFileSystem.supportsFileLink) {
      String target = srcPath;
      // Check if dst is link
      FileSystemEntityType type =
          await dstFileSystem.type(dstPath, followLinks: false);

      bool deleteDst = false;
      if (type != FileSystemEntityType.NOT_FOUND) {
        if (type == FileSystemEntityType.LINK) {
          // check target
          if (await dstFileSystem.newLink(dstPath).target() != target) {
            deleteDst = true;
          } else {
            // nothing to do
            return 0;
          }
        } else {
          deleteDst = true;
        }
      }

      if (deleteDst) {
        await dstFile.delete();
      }

      await dstFileSystem.newLink(dstPath).create(target, recursive: true);
      count++;
      return count;
    }

    // Handle modified date
    if (options.checkSizeAndModifiedDate == true) {
      FileStat srcStat = await srcFile.stat();
      FileStat dstStat = await dstFile.stat();
      if ((srcStat.size == dstStat.size) &&
          (srcStat.modified.compareTo(dstStat.modified) <= 0)) {
        // should be same...
        return 0;
      }
    }

    count += await copyFileContent(srcFile, dstFile);
  }

  return count;
}

/// Copy the file content
Future<int> copyFileContent(File src, File dst) async {
  var inStream = src.openRead();
  StreamSink<List<int>> outSink = dst.openWrite();
  try {
    await inStream.pipe(outSink);
  } catch (_) {
    Directory parent = dst.parent;
    if (!await parent.exists()) {
      await parent.create(recursive: true);
    }
    outSink = dst.openWrite();
    inStream = src.openRead();
    await inStream.pipe(outSink);
  }
  return 1;
}
