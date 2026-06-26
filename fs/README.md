# fs_shim

A portable file system library for Dart and Flutter.

`fs_shim` exposes a single asynchronous `File`/`Directory`/`Link` API (a subset
of `dart:io`) that runs the same code on:

- 🖥 Dart VM / Flutter native (IO)
- 🌐 Web — browser storage (through [`idb_shim`](https://pub.dev/packages/idb_shim))
- 🌐 Web — OPFS (Origin Private File System), a thin layer over the native browser API
- 🧪 Tests / in-memory (through `idb_shim`)

## API supported

It contains a subset of the io `File`/`Directory` API. Basically all sync methods
are removed since on the web indexedDB (and OPFS) cannot be accessed in a
synchronous way. All operations are asynchronous and return a `Future` (or a
`Stream` for `openRead`/`list`).

Classes

- `File` (create, openWrite, openRead, writeAsBytes, writeAsString, copy)
- `Link` (create, target)
- `Directory` (create, list)
- `FileSystem` (file, link, directory, type, isFile, isDirectory, isLink)
- `FileSystemEntity` (path, exists, delete, rename, absolute, isAbsolute, stat, parent)
- `FileStat`
- `FileSystemEntityType`
- `FileSystemException`

Static method

- `Directory.current`
- `FileSystemEntity.isFile`
- `FileSystemEntity.isDirectory`
- `FileSystemEntity.isLink`

Static and `File`/`Directory`/`Link` constructors use `fileSystemDefault` which
is platform dependent (web or io).

## Implementations

| File system          | Import                            | Platform | Links | Random access |
|----------------------|-----------------------------------|----------|-------|---------------|
| `fileSystemDefault`  | `package:fs_shim/fs_shim.dart`    | all      | io    | io / web      |
| `fileSystemIo`       | `package:fs_shim/fs_shim.dart`    | io       | ✅¹    | ✅            |
| `fileSystemMemory`   | `package:fs_shim/fs_shim.dart`    | all      | ✅    | ✅            |
| `fileSystemWeb`      | `package:fs_shim/fs_browser.dart` | web      | ✅    | ✅ (opt-in)   |
| `fileSystemOpfsWeb`  | `package:fs_shim/fs_opfs_web.dart`| web      | ❌    | ❌            |

¹ File links are not supported on Windows (`fs.supportsFileLink` returns `false`).

You can always check capabilities at runtime with `fs.supportsLink`,
`fs.supportsFileLink` and `fs.supportsRandomAccess`.

## Installation

Add the following dependency to your `pubspec.yaml`:

```yaml
dependencies:
  fs_shim: ^<latest>
```

## Usage

### In memory

A simple usage example:

```dart
import 'package:fs_shim/fs_shim.dart';
import 'package:path/path.dart';

Future<void> main() async {
  final fs = fileSystemMemory;

  // Create a top level directory
  final dir = fs.directory('/dir');

  // and a file in it
  final file = fs.file(join(dir.path, 'file'));

  // create a file
  await file.create(recursive: true);
  await file.writeAsString('Hello world!');

  // read a file
  print('file: ${await file.readAsString()}');

  // use a file link if supported
  if (fs.supportsFileLink) {
    final link = fs.link(join(dir.path, 'link'));
    await link.create(file.path);

    print('link: ${await fs.file(link.path).readAsString()}');
  }

  // list dir content
  print(await dir.list(recursive: true, followLinks: true).toList());
}
```

The same code runs unchanged against any other implementation: just swap the
`fs` instance.

### Using IO API

#### Using fs_shim.dart

You can simply replace in the above example:

```dart
final fs = fileSystemMemory;
```

by

```dart
final fs = fileSystemIo;
```

If you only target io, you can still use the `File` and `Directory`
constructors, replace

```dart
import 'dart:io'
    hide
    Directory,
    File,
    Link,
    FileSystemEntity,
    FileMode,
    FileStat,
    OSError,
    FileSystemException,
    FileSystemEntityType;

import 'package:fs_shim/fs_shim.dart';
```

by

```dart
import 'package:fs_shim/fs_io.dart';
```

Then a reduced set of the IO API can be used, same source code that might
require some cleanup if you import from existing code.

Simple example

```dart
import 'package:fs_shim/fs_io.dart';
import 'package:path/path.dart';

Future<void> main() async {
  final fs = fileSystemDefault;
  // safe place when running from package root
  final dirPath = join(Directory.current.path, 'test_out', 'example', 'dir');

  // Create a top level directory
  final dir = Directory(dirPath);
  print('dir: $dir');
  // delete its content
  if (await dir.exists()) {
    await dir.delete(recursive: true);
  }

  // and a file in it
  final file = File(join(dir.path, 'file'));

  // create a file
  await file.create(recursive: true);
  await file.writeAsString('Hello world!');

  // read a file
  print('file: ${await file.readAsString()}');

  // use a file link if supported
  if (fs.supportsFileLink) {
    final link = Link(join(dir.path, 'link'));

    await link.create(basename(file.path));
    final linkFile = File(link.path);
    print('link: ${await linkFile.readAsString()}');
  }

  // list dir content
  print(await dir.list(recursive: true, followLinks: true).toList());
}
```

### Browser usage

You can simply replace in the in-memory example:

```dart
final fs = fileSystemMemory;
```

by

```dart
import 'package:fs_shim/fs_browser.dart';

final fs = fileSystemWeb;
```

The default implementation on the browser uses `fileSystemWeb` (backed by
indexedDB through `idb_shim`).

### OPFS usage (Origin Private File System)

`fs_shim` also provides an implementation on top of the
browser [Origin Private File System](https://developer.mozilla.org/en-US/docs/Web/API/File_System_API/Origin_private_file_system)
(OPFS). It is a thin layer over the native `navigator.storage.getDirectory()`
API (using `dart:js_interop`, so it is Wasm compatible).

```dart
import 'package:fs_shim/fs_opfs_web.dart';

final fs = fileSystemOpfsWeb;
```

There is a single OPFS per origin, so `fileSystemOpfsWeb` returns a shared
instance. The same `File`/`Directory` code shown in the examples above runs
unchanged on OPFS.

When to use OPFS instead of `fileSystemWeb`:

- OPFS is backed directly by the browser's native file system primitives, which
  is well suited for storing larger files and binary content.
- `fileSystemWeb` (indexedDB) supports links and (opt-in) random access, which
  OPFS does not.

Limitations of the OPFS implementation:

- Links are not supported (`fs.supportsLink` / `fs.supportsFileLink` return
  `false`).
- Random access is not supported (`fs.supportsRandomAccess` returns `false`).
- Web only — `fileSystemOpfsWeb` relies on `navigator.storage.getDirectory()`.
  The import is safe on any platform, but accessing the instance off the web is
  not supported.

### Random access support

Random access is supported since version 2.1.0 on io and web (indexedDB).

The default web implementation is not optimized for random access (it might
change in the future). You can specify a paging parameter (initial testing is
good in some scenarios with a 16Kb page; you might tune it for your needs).

```dart
import 'package:fs_shim/fs_browser.dart';

// Use default paging 16Kb
final fs =
  fileSystemWeb.withIdbOptions(options: FileSystemIdbOptions.pageDefault);
```

Storage remains compatible if the options are changed.

Random access is not supported by the OPFS implementation.

### Utilities

* Lightweight glob support (`**`, `*` and `?` in a posix style path)
* Copy utilities (copy files, directories recursively)

## Testing

`fs_shim` is well suited for testing file system access in VM unit tests using
`fileSystemMemory`, then running the exact same code on io or the web.

### Dev dependencies

Stable

    fs_shim: any

Bleeding edge

    fs_shim:
        git: https://github.com/tekartik/fs_shim.dart

## Features and bugs

* On Windows file links are not supported (`fs.supportsFileLink` returns `false`)
* On Windows directory link targets are absolute
* On the web (indexedDB), the size of the file system is limited by the size
  limit of indexedDB databases (browser dependent)
* On the web (OPFS), links and random access are not supported

* Project [source code](https://github.com/tekartik/fs_shim.dart)
</content>
</invoke>
