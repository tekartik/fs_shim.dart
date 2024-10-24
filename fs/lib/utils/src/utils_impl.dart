// ignore_for_file: public_member_api_docs

library;

import 'package:fs_shim/src/common/fs_mixin.dart';
import 'package:fs_shim/src/common/import.dart';
import 'package:fs_shim/utils/copy.dart';
import 'package:path/path.dart' as p;
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

/// Set debug flag for copy (dev only)
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
@Deprecated('Dev only')
set fsCopyDebug(bool debug) => _fsCopyDebug = debug;

bool _fsDeleteDebug = false;

/// Set debug flag for delete (dev only)
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
@Deprecated('Dev only')
set fsDeleteDebug(bool debug) => _fsDeleteDebug = debug;

// should not be exported
List<Glob> globList(List<String>? expressions) {
  final globs = <Glob>[];
  if (expressions != null) {
    for (final expression in expressions) {
      globs.add(Glob(expression));
    }
  }
  return globs;
}

// for create/copy
mixin class OptionsDeleteMixin {
  bool delete = false;
}

mixin class OptionsCreateMixin {
  bool create = false;
}

mixin class OptionsRecursiveMixin {
  bool recursive = true;
}

mixin class OptionsFollowLinksMixin {
  bool followLinks = true;
}

mixin class OptionsExcludeMixin {
  List<String>? _exclude;

  List<String>? get exclude => _exclude;

  set exclude(List<String>? exclude) {
    _exclude = exclude;
    _excludeGlobs = null;
  }

  // follow glob
  List<Glob>? _excludeGlobs;

  List<Glob>? get excludeGlobs {
    _excludeGlobs ??= globList(exclude);

    return _excludeGlobs;
  }
}

mixin class OptionsIncludeMixin {
  List<String>? _include;

  List<String>? get include => _include;

  set include(List<String>? include) {
    _include = include;
    _includeGlobs = null;
  }

  // follow glob
  List<Glob>? _includeGlobs;

  List<Glob>? get includeGlobs {
    _includeGlobs ??= globList(include);

    return _includeGlobs;
  }
}

/// Create a directory recursively
Future<Directory> createDirectory(Directory dir,
    {CreateOptions? options}) async {
  options ??= defaultCreateOptions;
  if (options.delete) {
    await deleteDirectory(dir);
  }
  await dir.create(recursive: options.recursive);
  return dir;
}

/// Create a file recursively
Future<File> createFile(File file, {CreateOptions? options}) async {
  options ??= defaultCreateOptions;
  if (options.delete) {
    await deleteFile(file);
  }
  await file.create(recursive: options.recursive);
  return file;
}

/// Delete a directory recursively
Future deleteDirectory(Directory dir, {DeleteOptions? options}) async {
  options ??= defaultDeleteOptions;

  try {
    await dir.delete(recursive: options.recursive);
  } catch (e) {
    if (e is FileSystemException) {
      if (e.status != FileSystemException.statusNotFound) {
        if (!options.recursive &&
            e.status == FileSystemException.statusNotEmpty) {
          // ok
        } else {
          // ignore: avoid_print
          print('delete $dir failed $e');
        }
      }
    } else {
      // ignore: avoid_print
      print('delete $dir failed $e');
    }
  }
  if (options.create) {
    await dir.create(recursive: true);
  }
}

/// Delete a directory recursively
Future deleteFile(File file, {DeleteOptions? options}) async {
  options ??= defaultDeleteOptions;

  try {
    await file.delete(recursive: options.recursive);
  } catch (e) {
    if (e is FileSystemException) {
      if (e.status != FileSystemException.statusNotFound) {
        // ignore: avoid_print
        print('delete $file failed $e');
      }
    } else {
      // ignore: avoid_print
      print('delete $file failed $e');
    }
  }
  if (options.create) {
    await file.create(recursive: true);
  }
}

Future<int> copyDirectoryImpl(Directory src, Directory? dst,
    {CopyOptions? options}) async {
  options ??= defaultCopyOptions;
  if (await src.fs.isDirectory(src.path)) {
    // delete destination first?
    if (options.delete) {
      await deleteDirectory(dst!);
    }
    return await TopCopy(
            TopEntity(src.fs, src.path), TopEntity(dst!.fs, dst.path),
            options: options)
        .run();
  } else {
    throw ArgumentError('not a directory ($src)');
  }
}

Future<Directory> copyDirectory(Directory src, Directory? dst,
    {CopyOptions? options}) async {
  await copyDirectoryImpl(src, dst, options: options);
  return asDirectory(dst);
}

Future<int> copyFileImpl(File src, FileSystemEntity dst,
    {CopyOptions? options}) async {
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
    {Directory? dst, CopyOptions? options}) async {
  options ??= defaultCopyOptions;
  if (await src.fs.isDirectory(src.path)) {
    var operations =
        await TopSourceNode(TopEntity(src.fs, src.path), options: options)
            ._runTree();
    return operations
        .where((operation) => !operation.isDirectory!)
        .map((operation) => src.fs.file(operation.src!.path))
        .toList(growable: false);
  } else {
    throw ArgumentError('not a directory ($src)');
  }
}

Future<File> copyFile(File src, FileSystemEntity dst,
    {CopyOptions? options}) async {
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
    {CopyOptions? options}) async {
  await copyFileSystemEntityImpl(src, dst, options: options);
  return dst;
}

Future<int> copyFileSystemEntityImpl(FileSystemEntity src, FileSystemEntity dst,
    {CopyOptions? options}) async {
  if (await src.fs.isDirectory(src.path)) {
    return await copyDirectoryImpl(asDirectory(src), asDirectory(dst),
        options: options);
  } else if (await src.fs.isFile(src.path)) {
    return await copyFileImpl(asFile(src), dst, options: options);
  }
  return 0;
}

/// Copy the file content
Future<int> copyFileContent(File src, File dst) async {
  try {
    await src.copy(dst.path);
  } catch (_) {
    final parent = dst.parent;
    if (!await parent.exists()) {
      await parent.create(recursive: true);
    }
    await src.copy(dst.path);
  }
  /*
  var inStream = src.openRead();
  devPrint('openWrite1');
  var outSink = dst.openWrite();
  devPrint('openWrite2');
  try {
    await inStream.cast<List<int>>().pipe(outSink);
    devPrint('openWrite3');
  } catch (_) {
    devPrint('openWrite4');
    final parent = dst.parent;
    devPrint('openWrite5');
    if (!await parent.exists()) {
      await parent.create(recursive: true);
    }
    devPrint('openWrite6');
    outSink = dst.openWrite();
    inStream = src.openRead();
    await inStream.cast<List<int>>().pipe(outSink);
  }
  // Copy mode for unix executables
   */
  return 1;
}

/// Copy the file meta for executable
Future<int> copyFileMeta(File src, File dst) async {
  var srcMode = (await src.stat()).mode;
  var dstMode = (await dst.stat()).mode;
  if (dst is FileExecutableSupport) {
    if (dstMode != FileStat.modeNotSupported) {
      if (srcMode != FileStat.modeNotSupported) {
        if (_isUnixExecutable(srcMode) != _isUnixExecutable(dstMode)) {
          await (dst.setExecutablePermission(_isUnixExecutable(srcMode)));
        }
      }
    }
  }
  return 0;
}

abstract class EntityNode {
  EntityNode? get parent; // can be null
  FileSystem get fs; // cannot be null
  String get top;

  String? get sub;

  String? get basename;

  Iterable<String>? get parts;

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

mixin EntityNodeFsMixin implements EntityNode {
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

mixin EntityChildMixin implements EntityNode {
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

mixin EntityPathMixin implements EntityNode {
  String? _path;

  @override
  String get path {
    _path ??= fs.path.join(top, sub);

    return _path!;
  }
}

class TopEntity extends Object
    with EntityPathMixin, EntityNodeFsMixin, EntityChildMixin
    implements EntityNode {
  @override
  EntityNode? get parent => null;
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
  String? basename;
  String? _sub;

  @override
  String? get sub => _sub;
  List<String>? _parts;

  @override
  Iterable<String>? get parts => _parts;

  // Main one not used
  //CopyEntity.main(this.fs, String top) : _top = top;
  CopyEntity(this.parent, String relative) {
    //relative = _path.relative(relative, from: parent.path);
    basename = p.basename(relative);
    _parts = List.from(parent.parts!);
    if (relative != utilsCurrentFolderPart) {
      _parts!.addAll(contextPathSplit(fs.path, relative));
    }
    _sub = fs.path.join(parent.sub!, relative);
  }

  @override
  String toString() => '$sub';
}

abstract class CopyNode {
  EntityNode? get dst;

  EntityNode? get src;

  CopyOptions? get options;
}

mixin ActionNodeMixin {
  static int _staticId = 0;
}

mixin SourceNodeMixin implements CopyNode {
  int? _id;

  int? get id => _id;
}

mixin CopyNodeMixin implements CopyNode {
  int? _id;

  int? get id => _id;

  Future<int> runChild(CopyOptions? options, String srcRelative,
      [String? dstRelative]) {
    final copy = ChildCopy(this, options, srcRelative, dstRelative);

    // exclude?
    return copy.run();
  }
}

Future<int> _executeOperations(List<CopyNodeOperation> operations) async {
  var count = 0;
  for (var operation in operations) {
    count += await operation.execute(operation);
  }
  return count;
}

class TopCopy extends Object
    with CopyNodeMixin, TopNodeMixin
    implements CopyNode {
  TopCopy(TopEntity src, TopEntity dst, {CopyOptions? options}) {
    _init(src: src, dst: dst, options: options);
  }

  @override
  String toString() => '[$id] $src => $dst';

  // compat
  Future<int> run() async {
    if (fsCopyDebug) {
      // ignore: avoid_print
      print(this);
    }
    return await _executeOperations(await _runTree());
  }
}

mixin TopNodeMixin implements CopyNode, SourceNodeMixin {
  @override
  TopEntity get src => _src;

  CopyOptions? _options;

  @override
  CopyOptions? get options => _options;
  late TopEntity _src;

  @override
  TopEntity? get dst => _dst;

  // Null for src
  TopEntity? _dst;

  void _init(
      {required TopEntity src, TopEntity? dst, required CopyOptions? options}) {
    _src = src;
    _dst = dst;
    _id = ++ActionNodeMixin._staticId;
    _options = options ?? recursiveLinkOrCopyNewerOptions;
    if (fsCopyDebug) {
      // ignore: avoid_print
      print('src: $src');
      // ignore: avoid_print
      print('dst: $dst');
    }
  }

  Future<List<CopyNodeOperation>> _runTree() async {
    if (fsCopyDebug) {
      // ignore: avoid_print
      print(this);
    }
    // Somehow the top folder is accessed using an empty part
    final sourceNode = ChildSourceNode(this, null, utilsCurrentFolderPart);
    return await sourceNode._runTree();
  }
}

/// Special part name
const utilsCurrentFolderPart = '';

class TopSourceNode extends Object
    with SourceNodeMixin, TopNodeMixin
    implements CopyNode {
  TopSourceNode(TopEntity src, {CopyOptions? options}) {
    _init(src: src, options: options);
  }

  @override
  String toString() => '[$id] $src';
}

class ChildCopy extends Object
    with
        ChildNodeMixin,
        CopyNodeMixin,
        NodeExcludeMixin,
        NodeIncludeMixin,
        SourceNodeTreeRunnerMixin
    implements CopyNode {
  // if [options] is null, we'll use the parent options
  ChildCopy(CopyNode parent, CopyOptions? options, String srcRelative,
      [String? dstRelative]) {
    _init(parent, options, srcRelative, dstRelative);
  }

  //List<String> _

  @override
  String toString() => '  [$id] $src => $dst';

  Future<int> run() async {
    if (fsCopyDebug) {
      // ignore: avoid_print
      print('$this');
    }
    return await _executeOperations(await _runTree());
  }
}

var fileStatModeOtherExecute = 0x01;
var fileStatModeGroupExecute = 0x08;
var fileStatModeUserExecute = 0x40;

bool _isUnixExecutable(int mode) {
  return ((fileStatModeGroupExecute |
              fileStatModeOtherExecute |
              fileStatModeUserExecute) &
          mode) !=
      0;
}

class CopyNodeOperation extends CopyNode {
  final bool? isDirectory;
  @override
  final EntityNode? dst;
  @override
  final EntityNode? src;

  @override
  final CopyOptions? options;

  CopyNodeOperation({this.isDirectory, this.dst, this.src, this.options});

  Future<int> execute(CopyNodeOperation operation) async {
    if (operation.isDirectory!) {
      final dstDirectory = operation.dst!.asDirectory();
      if (!await dstDirectory.exists()) {
        await dstDirectory.create(recursive: true);
        return 1;
      }
      return 0;
    } else {
      final srcFile = src!.asFile();
      final dstFile = dst!.asFile();

      // Try to link first
      // allow link if asked and on the same file system
      if (options!.tryToLinkFile &&
          (src!.fs == dst!.fs) &&
          src!.fs.supportsFileLink) {
        final srcTarget = srcFile.absolute.path;
        // Check if dst is link
        final type = await dst!.type(followLinks: false);

        var deleteDst = false;
        if (type != FileSystemEntityType.notFound) {
          if (type == FileSystemEntityType.link) {
            // check target
            if (await dst!.asLink().target() != srcTarget) {
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

        await dst!.asLink().create(srcTarget, recursive: true);
        return 1;
      }
      // Handle modified date
      if (options!.checkSizeAndModifiedDate) {
        final srcStat = await srcFile.stat();
        final dstStat = await dstFile.stat();
        if ((dstStat.type != FileSystemEntityType.notFound) &&
            (srcStat.size == dstStat.size) &&
            (srcStat.modified.compareTo(dstStat.modified) <= 0)) {
          // should be same...
          return 0;
        }
      }

      var count = await copyFileContent(srcFile, dstFile);
      await copyFileMeta(srcFile, dstFile);
      return count;
    }
  }
}

mixin SourceNodeTreeRunnerMixin
    implements CopyNode, NodeIncludeMixin, NodeExcludeMixin, CopyNodeMixin {
  Future<List<CopyNodeOperation>> _runTree() async {
    var operations = <CopyNodeOperation>[];
    if (fsCopyDebug) {
      // ignore: avoid_print
      print('$this');
    }

    if (await src!.fs.isLink(src!.path) && (!options!.followLinks)) {
      return operations;
    }

    if (await src!.fs.isDirectory(src!.path)) {
      // to ignore?
      if (shouldExclude) {
        return operations;
      }

      var options = this.options;

      if (hasIncludeRules) {
        // when including dir, sub include options will be ignored
        if (shouldIncludeDir) {
          options = options!.clone..include = null;
        }
      }

      operations.add(CopyNodeOperation(
          isDirectory: true, src: src, dst: dst, options: options));

      // recursive
      if (options!.recursive) {
        final srcDirectory = src!.asDirectory();

        final futures = <Future>[];
        await srcDirectory
            .list(recursive: false, followLinks: options.followLinks)
            .listen((FileSystemEntity srcEntity) {
          final basename = src!.fs.path.basename(srcEntity.path);
          futures.add(_runTreeChild(options, basename).then((childOperations) {
            operations.addAll(childOperations);
          }));
        }).asFuture<void>();
        await Future.wait(futures);
      }
    } else if (await src!.fs.isFile(src!.path)) {
      // to ignore?
      if (shouldExcludeFile) {
        return operations;
      }

      if (hasIncludeRules) {
        if (!shouldIncludeFile) {
          return operations;
        }
      }

      operations.add(CopyNodeOperation(
          isDirectory: false, src: src, dst: dst, options: options));
    }

    return operations;
  }

  Future<List<CopyNodeOperation>> _runTreeChild(
    CopyOptions? options,
    String srcRelative,
    /*[String dstRelative]*/
  ) async {
    final sourceNode = ChildSourceNode(this, options, srcRelative);

    // exclude?
    return sourceNode._runTree();
  }
}

mixin ChildNodeMixin
    implements
        SourceNodeMixin,
        NodeExcludeMixin,
        NodeIncludeMixin,
        SourceNodeTreeRunnerMixin {
  CopyEntity? _src;

  @override
  CopyEntity? get src => _src;
  CopyEntity? _dst;

  @override
  CopyEntity? get dst => _dst;
  CopyNode? _parent;

  CopyNode? get parent => _parent;

  CopyOptions? _options;

  @override
  CopyOptions? get options => _options;

  @override
  OptionsExcludeMixin? get excludeOptions => options;

  @override
  OptionsIncludeMixin? get includeOptions => options;

  @override
  String? get srcSub => src!.sub;

  void _init(CopyNode parent, CopyOptions? options, String srcRelative,
      [String? dstRelative]) {
    _parent = parent;
    _options = options ??= parent.options;

    _id = ++ActionNodeMixin._staticId;

    dstRelative = dstRelative ?? srcRelative;
    _src = parent.src!.child(srcRelative);
    _dst = parent.dst?.child(dstRelative);
  }
}

class ChildSourceNode extends Object
    with
        ChildNodeMixin,
        SourceNodeMixin,
        NodeExcludeMixin,
        NodeIncludeMixin,
        SourceNodeTreeRunnerMixin
    implements CopyNode {
  // if [options] is null, we'll use the parent options
  ChildSourceNode(CopyNode parent, CopyOptions? options, String srcRelative) {
    _init(parent, options, srcRelative);
  }

  //List<String> _

  @override
  String toString() => '  [$id] $src';

  @override
  Future<int> runChild(CopyOptions? options, String srcRelative,
          [String? dstRelative]) =>
      throw UnsupportedError('temp');
}

mixin NodeExcludeMixin {
  OptionsExcludeMixin? get excludeOptions;

  String? get srcSub;

  bool get shouldExclude {
    // to ignore?
    if (excludeOptions!.excludeGlobs!.isNotEmpty) {
      // only test on sub
      for (final glob in excludeOptions!.excludeGlobs!) {
        if (glob.matches(srcSub!)) {
          return true;
        }
      }
    }
    return false;
  }

  bool get shouldExcludeFile {
    // to ignore?
    if (excludeOptions!.excludeGlobs!.isNotEmpty) {
      // only test on sub
      for (final glob in excludeOptions!.excludeGlobs!) {
        if (!glob.isDir) {
          if (glob.matches(srcSub!)) {
            return true;
          }
        }
      }
    }
    return false;
  }
}

mixin NodeIncludeMixin {
  OptionsIncludeMixin? get includeOptions;

  String? get srcSub;

  bool get hasIncludeRules => includeOptions!.include != null;

  bool get shouldIncludeDir {
    // to ignore?
    if (includeOptions!.includeGlobs!.isNotEmpty) {
      // only test on sub
      for (final glob in includeOptions!.includeGlobs!) {
        if (glob.isDir) {
          if (glob.matches(srcSub!)) {
            return true;
          }
        }
      }
    }
    return false;
  }

  bool get shouldIncludeFile {
    // to ignore?
    if (includeOptions!.includeGlobs!.isNotEmpty) {
      // only test on sub
      for (final glob in includeOptions!.includeGlobs!) {
        if (!glob.isDir) {
          if (glob.matches(srcSub!)) {
            return true;
          }
        }
      }
    }
    return false;
  }
}
