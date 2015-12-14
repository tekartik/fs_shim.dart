library fs_shim.utils.fcp;

import 'dart:io' hide FileSystemEntityType;
import 'dart:async';
//import 'package:logging/logging.dart' as log;
import 'package:path/path.dart';
import '../fs.dart';

Future _copyFile(String input, String output) {
  var inStream = new File(input).openRead();
  IOSink outSink;
  File outFile = new File(output);
  outSink = outFile.openWrite();
  return inStream.pipe(outSink).catchError((_) {
    Directory parent = outFile.parent;
    if (!parent.existsSync()) {
      parent.createSync(recursive: true);
    }
    outSink = outFile.openWrite();
    inStream = new File(input).openRead();
    return inStream.pipe(outSink);
  });
}

/// Copy the file content
Future<int> _copyFileContent(File src, File dst) async {
  var inStream = src.openRead();
  var outSink;
  outSink = dst.openWrite();
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

Future<int> _copyFileIfNewer(String input, String output) {
  return FileStat.stat(input).then((FileStat inputStat) {
    return FileStat.stat(output).then((FileStat outputStat) {
      if ((inputStat.size != outputStat.size) ||
          (inputStat.modified.isAfter(outputStat.modified))) {
        return _copyFile(input, output).then((_) {
          return 1;
        });
      } else {
        return 0;
      }
    }).catchError((e) {
      return _copyFile(input, output).then((_) {
        return 1;
      });
    });
  }) as Future<int>;
}

Directory emptyOrCreateDirSync(String path) {
  Directory dir = new Directory(path);
  if (dir.existsSync()) {
    dir.deleteSync(recursive: true);
  }
  dir.createSync(recursive: true);
  return dir;
}

/**
 * link dir (work on all platforms)
 */

/**
 * Not for windows
 */
Future<int> _linkFile(String target, String link) {
  if (Platform.isWindows) {
    throw "not supported on windows";
  }
  return _link(target, link);
}

/**
 * link dir (work on all platforms)
 */
Future<int> _link(String target, String link) {
  link = normalize(absolute(link));
  target = normalize(absolute(target));
  Link ioLink = new Link(link);

  // resolve target
  if (FileSystemEntity.isLinkSync(target)) {
    target = new Link(target).targetSync();
  }

  if (FileSystemEntity.isLinkSync(target)) {
    target = new Link(target).targetSync();
  }

  String existingLink = null;
  if (ioLink.existsSync()) {
    existingLink = ioLink.targetSync();
    //print(ioLink.resolveSymbolicLinksSync());
    if (existingLink == target) {
      return new Future.value(0);
    } else {
      ioLink.deleteSync();
    }
  }

  return ioLink.create(target).catchError((e) {
    Directory parent = new Directory(dirname(link));
    if (!parent.existsSync()) {
      try {
        parent.createSync(recursive: true);
      } catch (e) {
        // ignore the error
      }
    } else {
      // ignore the error and try again
      // print('linkDir failed($e) - target: $target, existingLink: $existingLink');
      // throw e;
    }
    return ioLink.create(target);
  }).then((_) => 1);
}

/**
 * on windows
 */
Future<int> _linkOrCopyFileIfNewer(String input, String output) {
  //devPrint('cplnk $input -> $output');
  if (Platform.isWindows) {
    return _copyFileIfNewer(input, output);
  } else {
    return _linkFile(input, output);
  }
}

class CopyOptions {
  final bool checkSizeAndModifiedDate;
  final bool tryToLinkFile;
  final bool tryToLinkDir;
  final bool followLinks;
  final List<String> exclude;
  CopyOptions(
      {this.checkSizeAndModifiedDate: false,
      this.tryToLinkFile: false,
      this.tryToLinkDir: false,
      this.followLinks: true,
      this.exclude});
}

CopyOptions defaultCopyOptions = new CopyOptions();
CopyOptions defaultCloneOptions = new CopyOptions(tryToLinkFile: true);

CopyOptions _safeOptions(CopyOptions options) {
  if (options == null) {
    options = defaultCopyOptions;
  }
  return options;
}

// Copy a file to its destination
Future<int> copyFileSystemEntity(FileSystemEntity src, FileSystemEntity dst,
    {CopyOptions options}) {
  options = _safeOptions(options);
  return _copyFileSystemEntity(src, dst, options);
}

Future<int> _copyFileSystemEntity(
    FileSystemEntity src, FileSystemEntity dst, CopyOptions options) async {
  int count = 0;

  if (await src.fs.isLink(src.path) && (!options.followLinks)) {
    return 0;
  }
  // awful
  if (await src.fs.isDirectory(src.path)) {
    Directory dstDirectory = dst.fs.newDirectory(dst.path);
    if (!await dstDirectory.exists()) {
      await dstDirectory.create(recursive: true);
      count++;
    }
  } else if (await src.fs.isFile(src.path)) {
    File srcFile = src.fs.newFile(src.path);
    File dstFile = dst.fs.newFile(dst.path);

    if (options.checkSizeAndModifiedDate == true) {
      FileStat srcStat = await srcFile.stat();
      FileStat dstStat = await dstFile.stat();
      if ((srcStat.size == dstStat.size) &&
          (srcStat.modified.compareTo(dstStat.modified) <= 0)) {
        // should be same...
        return 0;
      }
    }

    // allow link if asked and on the same file system
    if (options.tryToLinkFile &&
        (src.fs == dst.fs) &&
        src.fs.supportsFileLink) {
      String target = src.path;
      // Check if dst is link
      FileSystemEntityType type =
          await dst.fs.type(dst.path, followLinks: false);

      bool deleteDst = false;
      if (type != FileSystemEntityType.NOT_FOUND) {
        if (type == FileSystemEntityType.LINK) {
          // check target
          if (await dst.fs.newLink(dst.path).target() != target) {
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

      await dst.fs.newLink(dst.path).create(target, recursive: true);
      count++;
      return count;
    }

    count += await _copyFileContent(srcFile, dstFile);
  }

  return count;
}

/**
 * create the dirs but copy or link the files
 */
Future<int> _linkOrCopyFilesInDirIfNewer(String input, String output,
    {bool recursive: true, List<String> but}) {
  List<Future<int>> futures = new List();

  List<FileSystemEntity> entities =
      new Directory(input).listSync(recursive: false, followLinks: true);
  new Directory(output).createSync(recursive: true);
  entities.forEach((entity) {
    bool ignore = false;
    if (but != null) {
      if (but.contains(basename(entity.path))) {
        ignore = true;
      }
    }

    if (!ignore) {
      if (FileSystemEntity.isFileSync(entity.path)) {
        String file = relative(entity.path, from: input);
        futures
            .add(_linkOrCopyFileIfNewer(join(input, file), join(output, file)));
      } else if (FileSystemEntity.isDirectorySync(entity.path)) {
        if (recursive) {
          String dir = relative(entity.path, from: input);
          String outputDir = join(output, dir);

          futures
              .add(_linkOrCopyFilesInDirIfNewer(join(input, dir), outputDir));
        }
      }
    }
  });

  return Future.wait(futures).then((List<int> list) {
    int count = 0;
    list.forEach((delta) {
      count += delta;
    });
    return count;
  }) as Future<int>;
}

/**
 * Helper to copy recursively a source to a destination
 */
Future<int> cloneFiles(String src, String dst) {
  return FileSystemEntity.isDirectory(src).then((bool isDir) {
    if (isDir) {
      return _linkOrCopyFilesInDirIfNewer(src, dst, recursive: true);
    } else {
      return FileSystemEntity.isFile(src).then((bool isFile) {
        if (isFile) {
          return _linkOrCopyFileIfNewer(src, dst);
        } else {
          throw "${src} entity not found";
        }
      });
    }
  }) as Future<int>;
}
