library fs_shim.utils.src.utils_impl;

import 'dart:async';

import 'package:fs_shim/fs.dart';
import 'package:fs_shim/src/common/import.dart';
import 'package:fs_shim/utils/copy.dart';
import 'package:fs_shim/utils/glob.dart';
import 'package:path/path.dart' as _path;
//import 'package:logging/logging.dart' as log;

/*
bool _fsUtilsDebug = false;

bool get fsUtilsDebug => _fsUtilsDebug;

///
/// deprecated to prevent permanent use
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

bool _fsDeleteDebug = false;

bool get fsDeleteDebug => _fsDeleteDebug;

///
/// deprecated to prevent permanent use
///
/// Use:
///
///     fsDeleteDebug = true;
///
/// for debugging only
///
@deprecated
set fsDeleteDebug(bool debug) => _fsDeleteDebug = debug;

// should not be exported
List<Glob> globList(List<String> expressions) {
  List<Glob> globs = [];
  if (expressions != null) {
    for (String expression in expressions) {
      globs.add(Glob(expression));
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

class OptionsFollowLinksMixin {
  bool followLinks = true;
}

class OptionsExcludeMixin {
  List<String> _exclude;

  List<String> get exclude => _exclude;

  set exclude(List<String> exclude) {
    _exclude = exclude;
    _excludeGlobs = null;
  }

  // follow glob
  List<Glob> _excludeGlobs;

  List<Glob> get excludeGlobs {
    if (_excludeGlobs == null) {
      _excludeGlobs = globList(exclude);
    }
    return _excludeGlobs;
  }
}

class OptionsIncludeMixin {
  List<String> _include;

  List<String> get include => _include;

  set include(List<String> include) {
    _include = include;
    _includeGlobs = null;
  }

  // follow glob
  List<Glob> _includeGlobs;

  List<Glob> get includeGlobs {
    if (_includeGlobs == null) {
      _includeGlobs = globList(include);
    }
    return _includeGlobs;
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

/// Create a file recursively
Future<File> createFile(File file, {CreateOptions options}) async {
  options ??= defaultCreateOptions;
  if (options.delete) {
    await deleteFile(file);
  }
  await file.create(recursive: options.recursive);
  return file;
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
    await file.delete(recursive: options.recursive);
  } catch (e) {
    if (e is FileSystemException) {
      if (e.status != FileSystemException.statusNotFound) {
        print('delete $file failed $e');
      }
    } else {
      print('delete $file failed $e');
    }
  }
  if (options.create) {
    await file.create(recursive: true);
  }
}

Future<int> copyDirectoryImpl(Directory src, Directory dst,
    {CopyOptions options}) async {
  options ??= defaultCopyOptions;
  if (await src.fs.isDirectory(src.path)) {
    // delete destination first?
    if (options.delete) {
      await deleteDirectory(dst);
    }
    return await TopCopy(
            TopEntity(src.fs, src.path), TopEntity(dst.fs, dst.path),
            options: options)
        .run();
  } else {
    throw ArgumentError('not a directory ($src)');
  }
}

Future<Directory> copyDirectory(Directory src, Directory dst,
    {CopyOptions options}) async {
  await copyDirectoryImpl(src, dst, options: options);
  return asDirectory(dst);
}

Future<int> copyFileImpl(File src, FileSystemEntity dst,
    {CopyOptions options}) async {
  options ??= defaultCopyOptions;
  if (await src.fs.isFile(src.path)) {
    // delete destination first?
    if (options.delete) {
      await dst.delete(recursive: true);
    }
    return await TopCopy(TopEntity(src.fs, src.parent.path),
            TopEntity(dst.fs, dst.parent.path), options: options)
        .runChild(null, src.fs.path.basename(src.path),
            dst.fs.path.basename(dst.path));
    //await copyFileSystemEntity_(src, dst, options: options);
  } else {
    throw ArgumentError('not a file ($src)');
  }
}

Future<List<File>> copyDirectoryListFiles(Directory src,
    {CopyOptions options}) async {
  options ??= defaultCopyOptions;
  if (await src.fs.isDirectory(src.path)) {
    return await TopSourceNode(TopEntity(src.fs, src.path), options: options)
        .run();
  } else {
    throw ArgumentError('not a directory ($src)');
  }
}

Future<File> copyFile(File src, FileSystemEntity dst,
    {CopyOptions options}) async {
  await copyFileImpl(src, dst, options: options);
  return asFile(dst);
}

/*
Future<Link> copyLink(Link src, Link dst, {CopyOptions options}) async {
  if (await src.fs.isLink(src.path)) {
    await copyFileSystemEntity_(src, dst, options: options);
  } else {
    throw new ArgumentError('not a link ($src)');
  }
  return dst;
}
*/

// Copy a file to its destination
Future<FileSystemEntity> copyFileSystemEntity(
    FileSystemEntity src, FileSystemEntity dst,
    {CopyOptions options}) async {
  await copyFileSystemEntityImpl(src, dst, options: options);
  return dst;
}

Future<int> copyFileSystemEntityImpl(FileSystemEntity src, FileSystemEntity dst,
    {CopyOptions options}) async {
  if (await src.fs.isDirectory(src.path)) {
    return await copyDirectoryImpl(asDirectory(src), asDirectory(dst),
        options: options);
  } else if (await src.fs.isFile(src.path)) {
    return await copyFileImpl(asFile(src), dst, options: options);
  }
  return 0;
}
/*
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
  }

  if (await srcFileSystem.isDirectory(srcPath)) {
    Directory dstDirectory = dstFileSystem.directory(dstPath);
    if (!await dstDirectory.exists()) {
      await dstDirectory.create(recursive: true);
      count++;
    }

    // recursive
    if (options.recursive) {
      Directory srcDirectory = srcFileSystem.directory(srcPath);

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
    File srcFile = srcFileSystem.file(srcPath);
    File dstFile = dstFileSystem.file(dstPath);

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
*/

/// Copy the file content
Future<int> copyFileContent(File src, File dst) async {
  var inStream = src.openRead();
  StreamSink<List<int>> outSink = dst.openWrite();
  try {
    await inStream.cast<List<int>>().pipe(outSink);
  } catch (_) {
    Directory parent = dst.parent;
    if (!await parent.exists()) {
      await parent.create(recursive: true);
    }
    outSink = dst.openWrite();
    inStream = src.openRead();
    await inStream.cast<List<int>>().pipe(outSink);
  }
  return 1;
}

Future emptyOrCreateDirectory(Directory dir) async {
  await dir.delete(recursive: true);
  await dir.create(recursive: true);
}

abstract class EntityNode {
  EntityNode get parent; // can be null
  FileSystem get fs; // cannot be null
  String get top;

  String get sub;

  String get basename;

  Iterable<String> get parts;

  String get path; // full path
  /// create a child
  CopyEntity child(String basename);

  Directory asDirectory();

  File asFile();

  Link asLink();

  Future<bool> isDirectory();

  Future<bool> isFile();

  Future<bool> isLink();

  Future<FileSystemEntityType> type({bool followLinks = true});

  @override
  String toString() => '$sub';
}

abstract class EntityNodeFsMixin implements EntityNode {
  @override
  Directory asDirectory() => fs.directory(path);

  @override
  File asFile() => fs.file(path);

  @override
  Link asLink() => fs.link(path);

  @override
  Future<bool> isDirectory() => fs.isDirectory(path);

  @override
  Future<bool> isFile() => fs.isFile(path);

  @override
  Future<bool> isLink() => fs.isLink(path);

  @override
  Future<FileSystemEntityType> type({bool followLinks = true}) =>
      fs.type(path, followLinks: followLinks);
}

abstract class EntityChildMixin implements EntityNode {
  @override
  CopyEntity child(String basename) => CopyEntity(this, basename);
}

/*
abstract class EntityPartsMixin implements EntityNode {
  String _parts;
  @override
  String get parts => _parts;
}
*/

abstract class EntityPathMixin implements EntityNode {
  String _path;

  @override
  String get path {
    if (_path == null) {
      _path = fs.path.join(top, sub);
    }
    return _path;
  }
}

class TopEntity extends Object
    with EntityPathMixin, EntityNodeFsMixin, EntityChildMixin
    implements EntityNode {
  @override
  EntityNode get parent => null;
  @override
  final FileSystem fs;
  @override
  final String top;

  @override
  String get sub => '';

  @override
  String get basename => '';

  @override
  List<String> get parts => [];

  //TopEntity.parts(this.fs, List<String> parts);
  TopEntity(this.fs, this.top);

  @override
  String toString() => top;
}

TopEntity topEntityPath(FileSystem fs, String top) => TopEntity(fs, top);

TopEntity fsTopEntity(FileSystemEntity entity) =>
    TopEntity(entity.fs, entity.path);

class CopyEntity extends Object
    with EntityPathMixin, EntityNodeFsMixin, EntityChildMixin
    implements EntityNode {
  @override
  EntityNode parent; // cannot be null
  @override
  FileSystem get fs => parent.fs;

  @override
  String get top => parent.top;
  @override
  String basename;
  String _sub;

  @override
  String get sub => _sub;
  List<String> _parts;

  @override
  Iterable<String> get parts => _parts;

  // Main one not used
  //CopyEntity.main(this.fs, String top) : _top = top;
  CopyEntity(this.parent, String relative) {
    //relative = _path.relative(relative, from: parent.path);
    basename = _path.basename(relative);
    _parts = List.from(parent.parts);
    _parts.addAll(splitParts(relative));
    _sub = fs.path.join(parent.sub, relative);
  }

  @override
  String toString() => '$sub';
}

abstract class CopyNode extends SourceNode {
  EntityNode get dst;
}

abstract class SourceNode {
  EntityNode get src;

  CopyOptions get options;
}

abstract class ActionNodeMixin {
  static int _staticId = 0;
}

abstract class SourceNodeMixin implements SourceNode {
  int _id;

  int get id => _id;

  Future<List<File>> runChild(CopyOptions options, String srcRelative,
      [String dstRelative]) {
    ChildSourceNode sourceNode = ChildSourceNode(this, options, srcRelative);

    // exclude?
    return sourceNode.run();
  }
}

abstract class CopyNodeMixin implements CopyNode {
  int _id;

  int get id => _id;

  Future<int> runChild(CopyOptions options, String srcRelative,
      [String dstRelative]) {
    ChildCopy copy = ChildCopy(this, options, srcRelative, dstRelative);

    // exclude?
    return copy.run();
  }
}

class TopCopy extends Object with CopyNodeMixin implements CopyNode {
  CopyOptions _options;

  TopCopy(this.src, this.dst, {CopyOptions options}) {
    _id = ++ActionNodeMixin._staticId;
    _options = options ?? recursiveLinkOrCopyNewerOptions;
  }

  int count = 0;

  @override
  CopyOptions get options => _options;
  @override
  final TopEntity src;
  @override
  final TopEntity dst;

  @override
  String toString() => '[$id] $src => $dst';

  Future<int> run() async {
    if (fsCopyDebug) {
      print(this);
    }
    // Somehow the top folder is accessed using an empty part
    ChildCopy copy = ChildCopy(this, null, '');
    return await copy.run();
  }
}

class TopSourceNode extends Object with SourceNodeMixin implements SourceNode {
  CopyOptions _options;

  TopSourceNode(this.src, {CopyOptions options}) {
    _id = ++ActionNodeMixin._staticId;
    _options = options ?? recursiveLinkOrCopyNewerOptions;
  }

  int count = 0;

  @override
  CopyOptions get options => _options;
  @override
  final TopEntity src;

  @override
  String toString() => '[$id] $src';

  Future<List<File>> run() async {
    if (fsCopyDebug) {
      print(this);
    }
    // Somehow the top folder is accessed using an empty part
    ChildSourceNode sourceNode = ChildSourceNode(this, null, '');
    return await sourceNode.run();
  }
}

class ChildCopy extends Object
    with CopyNodeMixin, NodeExcludeMixin, NodeIncludeMixin
    implements CopyNode {
  @override
  CopyEntity src;
  @override
  CopyEntity dst;
  final CopyNode parent;
  @override
  CopyOptions options;

  @override
  OptionsExcludeMixin get excludeOptions => options;

  @override
  OptionsIncludeMixin get includeOptions => options;

  @override
  String get srcSub => src.sub;

  // if [options] is null, we'll use the parent options
  ChildCopy(this.parent, this.options, String srcRelative,
      [String dstRelative]) {
    if (options == null) {
      options = parent.options;
    }
    _id = ++ActionNodeMixin._staticId;

    dstRelative = dstRelative ?? srcRelative;
    //CopyEntity srcParent = parent.srcEntity;

    src = parent.src.child(srcRelative);
    dst = parent.dst.child(dstRelative);

    //srcEntity = new CopyEntity()
  }

  //List<String> _

  @override
  String toString() => '  [$id] $src => $dst';

  Future<int> run() async {
    int count = 0;
    if (fsCopyDebug) {
      print("$this");
    }

    if (await src.fs.isLink(src.path) && (!options.followLinks)) {
      return 0;
    }

    if (await src.fs.isDirectory(src.path)) {
      // to ignore?
      if (shouldExclude) {
        return 0;
      }

      CopyOptions options = this.options;

      if (hasIncludeRules) {
        // when including dir, sub include options will be ignored
        if (shouldIncludeDir) {
          options = options.clone..include = null;
        }
      }

      Directory dstDirectory = dst.asDirectory();
      if (!await dstDirectory.exists()) {
        await dstDirectory.create(recursive: true);
        count++;
      }

      // recursive
      if (options.recursive) {
        Directory srcDirectory = src.asDirectory();

        List<Future> futures = [];
        await srcDirectory
            .list(recursive: false, followLinks: options.followLinks)
            .listen((FileSystemEntity srcEntity) {
          String basename = src.fs.path.basename(srcEntity.path);
          futures.add(runChild(options, basename).then((int stepCount) {
            count += stepCount;
          }));
        }).asFuture();
        await Future.wait(futures);
      }
    } else if (await src.fs.isFile(src.path)) {
      // to ignore?
      if (shouldExcludeFile) {
        return 0;
      }

      if (hasIncludeRules) {
        if (!shouldIncludeFile) {
          return 0;
        }
      }

      File srcFile = src.asFile();
      File dstFile = dst.asFile();

      // Try to link first
      // allow link if asked and on the same file system
      if (options.tryToLinkFile &&
          (src.fs == dst.fs) &&
          src.fs.supportsFileLink) {
        String srcTarget = srcFile.absolute.path;
        // Check if dst is link
        FileSystemEntityType type = await dst.type(followLinks: false);

        bool deleteDst = false;
        if (type != FileSystemEntityType.notFound) {
          if (type == FileSystemEntityType.link) {
            // check target
            if (await dst.asLink().target() != srcTarget) {
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
          //devPrint('Deleting $dstFile');
          await dstFile.delete(recursive: true);
          //devPrint('Deleted $dstFile');
        }

        await dst.asLink().create(srcTarget, recursive: true);
        count++;
        return count;
      }

      // Handle modified date
      if (options.checkSizeAndModifiedDate == true) {
        FileStat srcStat = await srcFile.stat();
        FileStat dstStat = await dstFile.stat();
        if ((dstStat.type != FileSystemEntityType.notFound) &&
            (srcStat.size == dstStat.size) &&
            (srcStat.modified.compareTo(dstStat.modified) <= 0)) {
          // should be same...
          return 0;
        }
      }

      count += await copyFileContent(srcFile, dstFile);
    }

    return count;
  }
}

class ChildSourceNode extends Object
    with SourceNodeMixin, NodeExcludeMixin, NodeIncludeMixin
    implements SourceNode {
  @override
  CopyEntity src;
  final SourceNode parent;
  @override
  CopyOptions options;

  @override
  OptionsExcludeMixin get excludeOptions => options;

  @override
  OptionsIncludeMixin get includeOptions => options;

  @override
  String get srcSub => src.sub;

  // if [options] is null, we'll use the parent options
  ChildSourceNode(this.parent, this.options, String srcRelative) {
    if (options == null) {
      options = parent.options;
    }
    _id = ++ActionNodeMixin._staticId;

    src = parent.src.child(srcRelative);
  }

  //List<String> _

  @override
  String toString() => '  [$id] $src';

  Future<List<File>> run() async {
    List<File> entities = [];
    if (fsCopyDebug) {
      print("$this");
    }

    if (await src.fs.isLink(src.path) && (!options.followLinks)) {
      return entities;
    }

    if (await src.fs.isDirectory(src.path)) {
      // to ignore?
      if (shouldExclude) {
        return entities;
      }

      CopyOptions options = this.options;

      if (hasIncludeRules) {
        // when including dir, sub include options will be ignored
        if (shouldIncludeDir) {
          options = options.clone..include = null;
        }
      }
      // recursive
      if (options.recursive) {
        Directory srcDirectory = src.asDirectory();

        List<Future> futures = [];
        await srcDirectory
            .list(recursive: false, followLinks: options.followLinks)
            .listen((FileSystemEntity srcEntity) {
          String basename = src.fs.path.basename(srcEntity.path);
          futures
              .add(runChild(options, basename).then((List<File> childEntities) {
            entities.addAll(childEntities);
          }));
        }).asFuture();
        await Future.wait(futures);
      }
    } else if (await src.fs.isFile(src.path)) {
      // to ignore?
      if (shouldExcludeFile) {
        return entities;
      }

      if (hasIncludeRules) {
        if (!shouldIncludeFile) {
          return entities;
        }
      }

      File srcFile = src.asFile();

      entities.add(srcFile);
    }

    return entities;
  }
}

abstract class NodeExcludeMixin {
  OptionsExcludeMixin get excludeOptions;

  String get srcSub;

  bool get shouldExclude {
    // to ignore?
    if (excludeOptions.excludeGlobs.isNotEmpty) {
      // only test on sub
      for (Glob glob in excludeOptions.excludeGlobs) {
        if (glob.matches(srcSub)) {
          return true;
        }
      }
    }
    return false;
  }

  bool get shouldExcludeFile {
    // to ignore?
    if (excludeOptions.excludeGlobs.isNotEmpty) {
      // only test on sub
      for (Glob glob in excludeOptions.excludeGlobs) {
        if (!glob.isDir) {
          if (glob.matches(srcSub)) {
            return true;
          }
        }
      }
    }
    return false;
  }
}

abstract class NodeIncludeMixin {
  OptionsIncludeMixin get includeOptions;

  String get srcSub;

  bool get hasIncludeRules => includeOptions.include != null;

  bool get shouldIncludeDir {
    // to ignore?
    if (includeOptions.includeGlobs.isNotEmpty) {
      // only test on sub
      for (Glob glob in includeOptions.includeGlobs) {
        if (glob.isDir) {
          if (glob.matches(srcSub)) {
            return true;
          }
        }
      }
    }
    return false;
  }

  bool get shouldIncludeFile {
    // to ignore?
    if (includeOptions.includeGlobs.isNotEmpty) {
      // only test on sub
      for (Glob glob in includeOptions.includeGlobs) {
        if (!glob.isDir) {
          if (glob.matches(srcSub)) {
            return true;
          }
        }
      }
    }
    return false;
  }
}
