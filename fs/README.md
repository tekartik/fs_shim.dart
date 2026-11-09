# fs_shim

A portable file system API for Dart and Flutter: `File`, `Directory` and `Link`
(an asynchronous subset of `dart:io`) behind a `FileSystem` object. The same
code runs on io (Dart VM, Flutter mobile and desktop), in the browser
(IndexedDB or OPFS) and in memory (tests).

[![pub package](https://img.shields.io/pub/v/fs_shim.svg)](https://pub.dev/packages/fs_shim)

## Getting started

Add the dependency:

```sh
dart pub add fs_shim
```

Write your code against a `FileSystem`, then pick one:

```dart
import 'package:fs_shim/fs_shim.dart';

Future<void> main() async {
  // io on the Dart VM and Flutter native, IndexedDB in the browser.
  final fs = fileSystemDefault;

  final dir = fs.directory(fs.path.join(fs.currentDirectory.path, 'demo'));
  await dir.create(recursive: true);
  final file = dir.file('hello.txt');
  await file.writeAsString('Hello world!');
  print(await file.readAsString()); // Hello world!
  await dir.delete(recursive: true);
}
```

Every call is asynchronous (there is no `...Sync` method): the browser storage
cannot be read synchronously.

| Platform                              | File system                               | Needs                                   |
|---------------------------------------|-------------------------------------------|-----------------------------------------|
| Dart VM, Flutter mobile and desktop   | `fileSystemIo` (the default there)        | nothing                                 |
| Browser, Flutter web (dart2js, wasm)  | `fileSystemWeb` on IndexedDB (the default) | IndexedDB, size limited by the browser quota |
| Browser, Flutter web (dart2js, wasm)  | `fileSystemOpfsWeb` on OPFS               | `navigator.storage.getDirectory()`      |
| Everywhere, for tests                 | `fileSystemMemory`, `newFileSystemMemory()` | nothing (content lost at exit)        |

Every import is safe on every platform. Reading `fileSystemIo` on the web, or
`fileSystemWeb` / `fileSystemOpfsWeb` off the web, throws `UnimplementedError`.

## Which file system to use

| File system                               | Import                              | Links | Random access     |
|-------------------------------------------|-------------------------------------|-------|-------------------|
| `fileSystemDefault`                       | `package:fs_shim/fs_shim.dart`      | ✅¹    | ✅                 |
| `fileSystemIo`                            | `package:fs_shim/fs_shim.dart`      | ✅¹    | ✅                 |
| `fileSystemMemory`, `newFileSystemMemory()` | `package:fs_shim/fs_memory.dart`  | ✅     | ✅                 |
| `fileSystemWeb`, `getFileSystemWeb()`, `newFileSystemWeb()` | `package:fs_shim/fs_browser.dart` | ✅ | ✅ (paging for speed, see below) |
| `fileSystemOpfsWeb`                       | `package:fs_shim/fs_opfs_web.dart`  | ❌     | ❌                 |

¹ No file links on Windows (`fs.supportsFileLink` is `false`).

- `fileSystemDefault` is `fileSystemWeb` on the web and `fileSystemIo`
  elsewhere. The `File(path)`, `Directory(path)` and `Link(path)` constructors
  use it. It is a variable: a test can assign `newFileSystemMemory()` to it.
- `fileSystemMemory` is shared by the whole program; `newFileSystemMemory()`
  creates an empty one (one per test).
- Prefer passing a `FileSystem` to your code over using `fileSystemDefault`:
  the code then runs unchanged on any implementation.
- Check capabilities at runtime with `fs.supportsLink`, `fs.supportsFileLink`
  and `fs.supportsRandomAccess`.

## Common pitfalls

- Build paths with the file system's own context, `fs.path.join(...)`, or
  `dir.file('name')`. Memory, IndexedDB and OPFS paths are posix (root `/`)
  on every host; the top-level `join` of `package:path` uses `\` on Windows.
- `writeAsString`, `writeAsBytes` and `openWrite` do not create the parent
  directory: call `file.create(recursive: true)` (or
  `file.parent.create(recursive: true)`) first, or use `writeString` from
  `package:fs_shim/utils/read_write.dart`.
- `writeAsBytes` takes a `Uint8List`, not a `List<int>`.
- Do not import `dart:io` next to `fs_shim.dart`: `File`, `Directory`... clash.
  For io only code, import `package:fs_shim/fs_io.dart` instead (see below).
- Catch the `FileSystemException` of fs_shim and test its `status`
  (`FileSystemException.statusNotFound`...), not the `dart:io` one.
- `await sink.close()` after `file.openWrite()`; the content is written once
  `close()` (and `done`) complete.
- `CopyOptions()` of `package:fs_shim/utils/copy.dart` is not recursive: pass
  `recursive: true` or use `defaultCopyOptions`.
- `entity.exists()` checks the type of the entity on io only. When the kind
  matters, use `fs.isFile(path)`, `fs.isDirectory(path)` or `fs.type(path)`.

## Usage

### In memory

```dart
import 'package:fs_shim/fs_shim.dart';

Future<void> main() async {
  final fs = fileSystemMemory;

  // A file in a top level directory
  final dir = fs.directory('/dir');
  final file = dir.file('file');

  await file.create(recursive: true);
  await file.writeAsString('Hello world!');
  print('file: ${await file.readAsString()}');

  // Use a file link if supported
  if (fs.supportsFileLink) {
    final link = dir.link('link');
    await link.create(file.path);
    print('link: ${await fs.file(link.path).readAsString()}');
  }

  // List the directory content
  print(await dir.list(recursive: true, followLinks: true).toList());
}
```

The same code runs unchanged on another implementation: only the `fs`
instance changes.

### io

Use `fileSystemIo` (or `fileSystemDefault`) from `fs_shim.dart`.

To port existing io only code, replace

```dart
import 'dart:io';
```

with

```dart
import 'package:fs_shim/fs_io.dart';
```

It exports `dart:io` with `File`, `Directory`, `Link`, `FileSystemEntity`,
`FileSystemEntityType`, `FileMode`, `FileStat`, `FileSystemException` and
`OSError` replaced by the fs_shim ones, plus `fileSystemIo`. Only the
asynchronous methods remain. `wrapIoFile`/`unwrapIoFile` (and the same for
directories, links...) convert between `dart:io` and fs_shim objects.

```dart
import 'package:fs_shim/fs_io.dart';
import 'package:path/path.dart';

Future<void> main() async {
  final dir = Directory(join(Directory.current.path, '.dart_tool', 'demo'));
  await dir.create(recursive: true);
  final file = File(join(dir.path, 'file'));
  await file.writeAsString('Hello world!');
  print('file: ${await file.readAsString()}');
  print('os: ${Platform.operatingSystem}'); // still dart:io
}
```

### Browser: IndexedDB

```dart
import 'package:fs_shim/fs_browser.dart';

final fs = fileSystemWeb;
```

`fileSystemWeb` (the default on the web) stores the files in the IndexedDB
database `lfs.db` through [idb_shim](https://pub.dev/packages/idb_shim), with
links and random access. It stores each file in one record: good for whole
file reads and writes. For random access or partial reads of large files, use
16 KiB pages:

```dart
import 'package:fs_shim/fs_browser.dart';

// Same database, 16 KiB pages.
final fs = getFileSystemWeb();
// Another database, custom page size.
final cacheFs = newFileSystemWeb(
  name: 'cache.db',
  options: const FileSystemIdbOptions(pageSize: 64 * 1024),
);
```

Files stay readable when the page size changes: a file is converted when it
is next written.

### Browser: OPFS (Origin Private File System)

`fs_shim` also provides an implementation on top of the browser
[Origin Private File System](https://developer.mozilla.org/en-US/docs/Web/API/File_System_API/Origin_private_file_system),
a thin layer over the native `navigator.storage.getDirectory()` API (using
`dart:js_interop`, so it is wasm compatible).

```dart
import 'package:fs_shim/fs_opfs_web.dart';

final fs = fileSystemOpfsWeb;
```

There is a single OPFS per origin, `fileSystemOpfsWeb` is a shared instance.

When to use OPFS instead of `fileSystemWeb`:

- OPFS uses the browser's native file storage, well suited for large files
  and binary content.
- `fileSystemWeb` (IndexedDB) supports links and random access, OPFS does not
  (`fs.supportsLink`, `fs.supportsFileLink` and `fs.supportsRandomAccess` are
  `false`, `file.open()` throws `UnsupportedError`).

A file system can also be rooted at any JS `FileSystemDirectoryHandle` (File
System Access API), for example a directory picked by the user:

```dart
import 'package:fs_shim/fs_opfs_web.dart';

/// Call it from a click handler (pickers are Chromium only).
Future<FileSystem> pickDirectory() async {
  final handle = await FileSystemOpfsWeb.showDirectoryPicker(
    const FileSystemOpfsWebShowDirectoryPickerOptions(
      mode: FileSystemOpfsWebShowDirectoryPickerOptions.modeReadWrite,
    ),
  );
  return FileSystemOpfsWeb.withRootHandle(handle);
}
```

From a JS `FileSystemDirectoryHandle` of any interop binding, use
`FileSystemOpfsWeb.withRootHandle(FileSystemOpfsWebDirectoryHandle.fromJsObject(jsHandle))`.
Write operations need the `readwrite` permission. Handles do not survive a
page reload unless the application saves them (`handle.jsObject` in
IndexedDB) and asks for the permission again (`FileSystemOpfsWeb.queryPermission`,
`requestPermission`).

### Random access

`file.open(mode: ...)` returns a `RandomAccessFile` (`setPosition`, `read`,
`writeFrom`, `writeString`, `truncate`, `length`...) on io, memory and
IndexedDB. As in `dart:io`, `FileMode.write` empties an existing file; use
`FileMode.append` to keep the content and move with `setPosition`.

```dart
import 'package:fs_shim/fs_shim.dart';

Future<void> patchHeader(File file) async {
  final raf = await file.open(mode: FileMode.append);
  try {
    await raf.setPosition(0);
    await raf.writeString('v2');
  } finally {
    await raf.close();
  }
}
```

On the web, prefer a paged file system (`getFileSystemWeb()`) for random
access: without pages each write reads and rewrites the whole file.

### Links

`link.create(target)` takes an absolute target or one relative to the link's
directory. `fs.type(path)` follows links (pass `followLinks: false` to see the
link itself). As on io, a link loop is reported as not found (or as a
`FileSystemException`), and a recursive `list(followLinks: true)` reports a
link to a directory it is already listing as a `Link` instead of entering it
again.

### Sandbox

`fs.sandbox(path: dirPath)` (or `dir.sandbox()`) returns a `FileSystem` whose
root `/` is that directory: every path, `..` included, stays inside it.
`file.unsandbox()` gives the entity in the original file system.

### Utilities

- `package:fs_shim/utils/copy.dart`: copy a file or a directory tree, even
  between two file systems (`copyDirectory`, `copyFile`, `CopyOptions` with
  include/exclude globs).
- `package:fs_shim/utils/read_write.dart`: `writeString`, `writeLines`,
  `readString`, `readLines` (creating the parent directory),
  `dir.emptyOrCreate()`.
- `package:fs_shim/utils/glob.dart`: lightweight glob (`**`, `*` and `?` in a
  posix style path).
- `package:fs_shim/utils/path.dart`: convert between posix and windows paths.

## Testing

Write the code under test against a `FileSystem` and run it on a new memory
file system, then on the real one:

```dart
import 'package:fs_shim/fs_memory.dart';
import 'package:test/test.dart';

Future<int> countWords(File file) async =>
    (await file.readAsString()).split(' ').length;

void main() {
  late FileSystem fs;
  setUp(() => fs = newFileSystemMemory());
  test('countWords', () async {
    final file = fs.file('/doc.txt');
    await file.writeAsString('one two three');
    expect(await countWords(file), 3);
  });
}
```

To use the latest code from git:

```yaml
dependencies:
  fs_shim:
    git:
      url: https://github.com/tekartik/fs_shim.dart
      path: fs
```

## Limitations

- Asynchronous API only, a subset of `dart:io` (no `Process`, no watch, no
  permissions other than the executable bit on io).
- On Windows, file links are not supported (`fs.supportsFileLink` is `false`)
  and directory link targets are absolute.
- On the web, IndexedDB and OPFS storage are limited by the browser quota.
- OPFS: no links and no random access.

Source code: [github.com/tekartik/fs_shim.dart](https://github.com/tekartik/fs_shim.dart)
