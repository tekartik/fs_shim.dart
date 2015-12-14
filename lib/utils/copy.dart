library fs_shim.utils.copy;

import 'dart:async';
//import 'package:logging/logging.dart' as log;
import 'package:path/path.dart';
import '../fs.dart';
import '../src/common/fs_path.dart';
/// Copy the file content
Future<int> _copyFileContent(File src, File dst) async {
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

Future emptyOrCreateDirectory(Directory dir) async {
  await dir.delete(recursive: true);
  await dir.create(recursive: true);
}

class CopyOptions {
  final bool checkSizeAndModifiedDate;
  final bool tryToLinkFile;
  final bool tryToLinkDir; // not supported yet
  final bool followLinks;
  final bool recursive;
  final List<String> exclude;
  CopyOptions(
      {this.recursive: false,
      this.checkSizeAndModifiedDate: false,
      this.tryToLinkFile: false,
      this.tryToLinkDir: false,
      this.followLinks: true,
      this.exclude});
}

CopyOptions copyNewerOptions = new CopyOptions(checkSizeAndModifiedDate: true);
CopyOptions recursiveLinkOrCopyNewerOptions = new CopyOptions(
    recursive: true, checkSizeAndModifiedDate: true, tryToLinkFile: true);
CopyOptions defaultCloneOptions = new CopyOptions(tryToLinkFile: true);

CopyOptions _safeOptions(CopyOptions options) {
  if (options == null) {
    options = new CopyOptions();
  }
  return options;
}

// Copy a file to its destination
Future<int> copyFileSystemEntity(FileSystemEntity src, FileSystemEntity dst,
    {CopyOptions options}) {
  options = _safeOptions(options);
  return _copyFileSystemEntity(src.fs, src.path, dst.fs, dst.path, options);
}

Future<int> _copyFileSystemEntity(FileSystem srcFileSystem, String srcPath,
    FileSystem dstFileSystem, String dstPath, CopyOptions options) async {
  int count = 0;

  if (await srcFileSystem.isLink(srcPath) && (!options.followLinks)) {
    return 0;
  }

  // to ignore?
  if (options.exclude != null) {
    if (options.exclude.contains(basename(srcPath))) {
      return 0;
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
        futures.add(_copyFileSystemEntity(
            srcFileSystem,
            srcEntity.path,
            dstFileSystem,
            dstFileSystem.pathContext.join(dstPath, basename),
            options).then((int count_) {
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

    count += await _copyFileContent(srcFile, dstFile);
  }

  return count;
}
