---
name: fs-shim-filesystem
description: >-
  Use when writing Dart or Flutter code with package:fs_shim to read, write,
  list, copy or delete files and directories through a portable FileSystem
  (fileSystemDefault, fileSystemIo, fileSystemMemory, fs.file(), fs.directory(),
  fs.link(), File.readAsString/writeAsString/readAsBytes/writeAsBytes,
  openRead/openWrite/open, Directory.list/create/delete, stat, exists, rename,
  FileSystemException status codes, fs.path context, sandbox, tryCreate,
  emptyOrCreate) and the helpers in fs_shim/utils (copyDirectory, copyFile,
  CopyOptions, Glob, writeString, writeLines, readLines, childFile).
---

# fs_shim: one async File/Directory/Link API for every platform

`package:fs_shim` exposes an asynchronous subset of the `dart:io` file API
(`File`, `Directory`, `Link`, `FileSystemEntity`, `FileStat`, `FileMode`,
`FileSystemException`) behind a `FileSystem` object. The same code runs on the
VM and Flutter (`fileSystemIo`), in memory (`fileSystemMemory`), and in the
browser on IndexedDB (`fileSystemWeb`) or OPFS (`fileSystemOpfsWeb`). There is
no synchronous API.

```dart
import 'package:fs_shim/fs_shim.dart';

Future<String> readConfig(FileSystem fs, String dirPath) async {
  final file = fs.file(fs.path.join(dirPath, 'config.json'));
  if (!await file.exists()) {
    await file.create(recursive: true);
    await file.writeAsString('{}');
  }
  return file.readAsString();
}
```

## Guidelines

### Getting entities from a FileSystem

* Import `package:fs_shim/fs_shim.dart`. It gives the whole API plus the
  instances `fileSystemDefault`, `fileSystemIo`, `fileSystemMemory` and
  `fileSystemWeb`. Write functions that take a `FileSystem fs` parameter and
  create entities with `fs.file(path)`, `fs.directory(path)`, `fs.link(path)`.
* The constructors `File(path)`, `Directory(path)`, `Link(path)`, the statics
  `FileSystemEntity.isFile/isDirectory/isLink/type` and `Directory.current`
  all go through `fileSystemDefault` (io on the VM, IndexedDB on the web).
  Use them only when a global file system is acceptable.
* Build paths with the file system's own `package:path` context: `fs.path.join`,
  `fs.path.basename`, `fs.path.dirname`, `fs.path.isAbsolute`. Memory, web and
  OPFS file systems are posix with root `/` whatever the host OS; the io file
  system uses the native style. Do not use the top-level `join` of
  `package:path` for a file system you did not choose. `pathContext` is the
  deprecated name of `path`.
* `entity.fs` gives the file system back, `entity.parent` the containing
  `Directory`, `entity.absolute` an absolute entity, `entity.isAbsolute`.
* `FileSystem` and `Directory` both implement `FileSystemEntityParent`:
  `directory(path)`, `file(path)`, `link(path)`, `childPath(path)` and
  `directoryWith({String? path})`. On a `Directory` the argument is joined
  under it (`dir.file('a.txt')`). On a `FileSystem`, `file`/`directory`/`link`
  take the path as is, while `childPath` and `directoryWith` resolve relative
  to `fs.currentDirectory` (`directoryWith()` with no path returns
  `currentDirectory`).
* Check capabilities at runtime instead of assuming a platform:
  `fs.supportsLink`, `fs.supportsFileLink` (false on Windows io and on OPFS),
  `fs.supportsRandomAccess` (false on OPFS). `fs.name` is `'io'`, `'idb'`
  (memory and web) or `'opfs'`.
* Entities compare equal when they belong to the same file system and their
  normalized absolute paths are equal (`fs.pathEquals`, `fs.pathHashCode`).

### Files

* Every call returns a `Future` or a `Stream`; `await` them. There is no
  `existsSync`, `readAsStringSync`, `writeAsStringSync`.
* `file.create(recursive: true)` creates missing parent directories.
  `writeAsString`/`writeAsBytes`/`openWrite` create the file but not its
  parents; they throw `FileSystemException` (`statusNotFound`) when the parent
  is missing. Create the parent first, or use `writeString` from
  `package:fs_shim/utils/read_write.dart`, which retries after creating it.
* `writeAsBytes` takes a `Uint8List`, not a `List<int>`. `readAsBytes()`
  returns a `Future<Uint8List>`.
* `writeAsString(text, {mode, encoding, flush})` and `writeAsBytes(bytes,
  {mode, flush})` truncate by default (`FileMode.write`); pass
  `mode: FileMode.append` to append. `FileMode.read` is only valid for
  `open()`.
* Stream large content: `file.openRead([start, end])` is a
  `Stream<Uint8List>`; `file.openWrite({mode})` returns a `FileStreamSink`
  (a `StreamSink<List<int>>` with `flush()`). Feed it with `add(bytes)` or
  `addStream(stream)`, it has no `write(String)`; always `await sink.close()`.
* `file.copy(newPath)` returns the new `File` and replaces an existing file;
  `rename(newPath)` returns the entity at the new path; `delete()`.
* `exists()` only guarantees that something is at the path: io also checks
  the kind (a `File` on a directory path is false) but memory, web and OPFS
  do not. When the kind matters use `fs.isFile(path)`, `fs.isDirectory(path)`
  or `fs.type(path)`.
* `stat()` never throws: it returns a `FileStat` with `type`
  (`FileSystemEntityType.notFound` when missing), `size`, `modified` and
  `mode` (`FileStat.modeNotSupported`, `-1`, outside io).
* Random access when `fs.supportsRandomAccess`: `final raf = await
  file.open(mode: FileMode.write)`, then `writeFrom`, `writeString`,
  `writeByte`, `read(count)`, `readInto`, `readByte`, `setPosition`,
  `position()`, `length()`, `truncate(length)`, `flush()`, and `close()`.
  `open()` throws `UnsupportedError` on a file system without support.

### Directories

* `dir.create(recursive: true)` is a no-op on an existing directory and throws
  when a file is in the way (`statusAlreadyExists` on memory/web,
  `statusNotADirectory` on io). `dir.tryCreate()` (extension in
  `fs_shim.dart`) returns `true`/`false` and never throws.
* `dir.delete()` requires an empty directory (`statusNotEmpty` otherwise);
  `dir.delete(recursive: true)` removes everything, links are not followed.
  Deleting a missing entity throws `statusNotFound`; `dir.emptyOrCreate()`
  from `utils/read_write.dart` resets a directory without throwing.
* `dir.list({recursive, followLinks})` is a `Stream<FileSystemEntity>`; test
  each item with `is File`, `is Directory`, `is Link`. Item paths are the
  listed directory path joined with the child name. Order is not guaranteed
  and a missing directory is reported as a stream error.
* `fs.currentDirectory` is the process working directory on io and `/` on
  memory, web and OPFS. Relative paths resolve against it.

### Links

* Guard link code with `fs.supportsLink` (directory links) and
  `fs.supportsFileLink` (file links). `link.create(target)` takes an absolute
  target or one relative to the link's directory; `link.target()` reads it.
* `fs.type(path)` follows links by default; use `followLinks: false` (or
  `fs.isLink(path)`, which never follows) to detect `FileSystemEntityType.link`.
  `dir.list(followLinks: false)` yields `Link` objects instead of targets.

### Errors

* Catch fs_shim's `FileSystemException` (exported by `fs_shim.dart`), not the
  `dart:io` one. Inspect `e.status` against `FileSystemException.statusNotFound`,
  `statusAlreadyExists`, `statusNotADirectory`, `statusIsADirectory`,
  `statusNotEmpty`, `statusInvalidArgument`, `statusAccessError`; `e.path`,
  `e.message` and `e.osError` (`errorCode`, `message`) carry details.
* Never import `dart:io` unhidden next to `fs_shim.dart`: `File`, `Directory`
  and friends clash. For io-only code use `package:fs_shim/fs_io.dart`, which
  re-exports `dart:io` minus the shadowed types (see `fs-shim-platforms`).

### Sandboxing

* `fs.sandbox(path: dirPath)` returns a `FileSystem` whose root `/` is that
  directory (absolute, normalized); `dir.sandbox()` is the shortcut. Inside,
  `currentDirectory` is `/` and every path is confined; the result implements
  `FsShimSandboxedFileSystem` with `rootDirectory`, `delegatePath(path)` and
  `sandboxPath(path)` (throws `PathException` when outside the root).
* Sandboxing a sandbox never nests: it re-roots on the original file system.
  `fs.unsandbox({path})`, `file.unsandbox()` and `dir.unsandbox()` return the
  entity in the underlying file system (unchanged when not sandboxed).
* Path helpers on any `FileSystem`: `absolutePath(path)`, `normalizePath`,
  `pathEquals(a, b)`, `pathHashCode(path)`.

### Helpers in `package:fs_shim/utils/...`

* `utils/read_write.dart`: `writeString(file, text)`, `writeBytes(file,
  bytes)`, `writeLines(file, lines, {useCrLf})` create the parent when the
  first write fails and flush; `readString(file)`, `readLines(file)`;
  `dir.emptyOrCreate()`.
* `utils/copy.dart`: `copyDirectory(src, dst, options:)`, `copyFile(src,
  dst)`, `copyDirectoryListFiles(src, options:)`, `deleteDirectory(dir)`,
  `deleteFile(file)` (both swallow not-found), `createDirectory`,
  `createFile`. Source and destination may live on different file systems.
  `CopyOptions()` is **not** recursive by default: pass `recursive: true` or
  use `defaultCopyOptions`. `exclude`/`include` are posix globs relative to
  `src`; a trailing `/` targets directories (`'build/'`).
* `utils/glob.dart`: `Glob(expression).matches(path)` with `*`, `?` and `**`
  only (no braces or character classes).
* `utils/entity.dart`: `childFile(dir, 'name')`, `childDirectory`,
  `childLink`, `asFile(entity)`, `asDirectory`, `asLink`, `entityExists`.
* `utils/path.dart`: `toPosixPath`, `toWindowsPath`, `toNativePath`,
  `toContextPath(context, path)` convert separators between styles.

## Examples

### Create, write, read and list

```dart
import 'package:fs_shim/fs_shim.dart';

Future<void> demo(FileSystem fs) async {
  final dir = fs.directory(fs.path.join(fs.currentDirectory.path, 'notes'));
  await dir.create(recursive: true);

  final file = dir.file('today.txt');
  await file.writeAsString('Hello\n');
  await file.writeAsString('World\n', mode: FileMode.append);
  print(await file.readAsString()); // Hello\nWorld\n

  await for (final entity in dir.list(recursive: true)) {
    if (entity is File) {
      print('file ${entity.path} ${(await entity.stat()).size} bytes');
    } else if (entity is Directory) {
      print('dir  ${entity.path}');
    }
  }
}

Future<void> main() => demo(fileSystemMemory);
```

### Streaming write and read

```dart
import 'dart:convert';
import 'package:fs_shim/fs_shim.dart';

Future<void> writeLog(File file, Iterable<String> lines) async {
  final sink = file.openWrite(mode: FileMode.append);
  for (final line in lines) {
    sink.add(utf8.encode('$line\n'));
  }
  await sink.flush();
  await sink.close();
}

Future<int> countBytes(File file) async {
  var count = 0;
  await for (final chunk in file.openRead()) {
    count += chunk.length;
  }
  return count;
}
```

### Type checks, stat and error handling

```dart
import 'package:fs_shim/fs_shim.dart';

Future<void> inspect(FileSystem fs, String path) async {
  switch (await fs.type(path, followLinks: false)) {
    case FileSystemEntityType.file:
      final stat = await fs.file(path).stat();
      print('file, ${stat.size} bytes, modified ${stat.modified}');
    case FileSystemEntityType.directory:
      print('directory');
    case FileSystemEntityType.link:
      print('link to ${await fs.link(path).target()}');
    default:
      print('not found');
  }
}

Future<bool> removeIfEmpty(Directory dir) async {
  try {
    await dir.delete();
    return true;
  } on FileSystemException catch (e) {
    if (e.status == FileSystemException.statusNotEmpty) {
      return false;
    }
    if (e.status == FileSystemException.statusNotFound) {
      return true;
    }
    rethrow;
  }
}
```

### Copy a tree between file systems

```dart
import 'package:fs_shim/fs_shim.dart';
import 'package:fs_shim/utils/copy.dart';

/// Loads fixtures from disk into an in-memory file system.
Future<FileSystem> loadFixtures(String fixturesPath) async {
  final memory = fileSystemMemory;
  await copyDirectory(
    fileSystemIo.directory(fixturesPath),
    memory.directory('/fixtures'),
    options: CopyOptions(
      recursive: true,
      exclude: ['build/', '**/*.tmp'],
    ),
  );
  return memory;
}

/// Incremental copy: only newer or resized files are written.
Future<void> sync(Directory src, Directory dst) => copyDirectory(
      src,
      dst,
      options: CopyOptions(recursive: true, checkSizeAndModifiedDate: true),
    );
```

### Read/write helpers that create parents

```dart
import 'package:fs_shim/fs_shim.dart';
import 'package:fs_shim/utils/read_write.dart';

Future<void> saveSettings(FileSystem fs, List<String> lines) async {
  final file = fs.file(fs.path.join('app', 'settings', 'list.txt'));
  await writeLines(file, lines); // creates app/settings if needed
  final back = await readLines(file);
  assert(back.length == lines.length);
  await fs.directory('app').emptyOrCreate(); // wipe and recreate
}
```

### Sandbox a directory

```dart
import 'package:fs_shim/fs_shim.dart';

Future<void> workInSandbox(FileSystem fs, String rootPath) async {
  final sandbox = fs.sandbox(path: rootPath);
  // '/' is rootPath, everything is confined
  await sandbox.file('/data/a.txt').create(recursive: true);
  final real = sandbox.file('/data/a.txt').unsandbox();
  print(real.path); // <rootPath>/data/a.txt on fs
  print((sandbox as FsShimSandboxedFileSystem).rootDirectory.path);
}
```

### Random access

```dart
import 'package:fs_shim/fs_shim.dart';

Future<void> patchHeader(File file) async {
  if (!file.fs.supportsRandomAccess) {
    throw UnsupportedError('no random access on ${file.fs.name}');
  }
  final raf = await file.open(mode: FileMode.append);
  try {
    await raf.setPosition(0);
    await raf.writeString('v2');
    final length = await raf.length();
    await raf.setPosition(length - 4);
    print(await raf.read(4));
  } finally {
    await raf.close();
  }
}
```

### Glob matching

```dart
import 'package:fs_shim/utils/glob.dart';

final dartFiles = Glob('**/*.dart');
final ok = dartFiles.matches('lib/src/main.dart'); // true
final no = dartFiles.matches('pubspec.yaml'); // false
final dirOnly = Glob('build/').isDir; // true
```

## Common mistakes

* Passing a `List<int>` to `writeAsBytes`: it needs a `Uint8List`.
* Writing to `dir/sub/file.txt` before `sub` exists. Use
  `file.create(recursive: true)` or `writeString` from `utils/read_write.dart`.
* Using `package:path`'s global `join` on a memory or web file system when the
  host is Windows. Use `fs.path.join`.
* Calling `dart:io` sync methods; they do not exist here.
* Forgetting `await sink.close()` on `openWrite()`, or calling `sink.write()`
  (only `add`/`addStream` exist).
* Catching `dart:io`'s `FileSystemException` instead of fs_shim's.
* `CopyOptions()` without `recursive: true` copies only the top directory.
* Creating links without checking `fs.supportsLink` / `fs.supportsFileLink`.

## More

See [references/utils.md](references/utils.md) for the full `CopyOptions`,
`DeleteOptions` and `CreateOptions` fields, glob rules, path conversion
helpers, entity helpers, `fsIdbExportLines`/`fsIdbImport` snapshots and the
`fs_mixin.dart` building blocks for a custom `FileSystem`.
