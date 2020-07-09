# fs_shim

A portable file system library to allow working on io, browser (though idb_shim) and memory (through idb_shim).

[![Build Status](https://travis-ci.org/tekartik/fs_shim.dart.svg?branch=master)](https://travis-ci.org/tekartik/fs_shim.dart)

## API supported

It contains a subset of the io `File/Directory` API. Basically all sync methods are removed since
on the web indexedDB cannot be accessed in a synchronous way.

Classes

- File (create, openWrite, openRead, writeAsBytes, writeAsString, copy)
- Link (create, target)
- Directory (create, list)
- FileSystem (file, link, directory, type, isFile, isDirectory, isLink)
- FileSystemEntity (path, exists, delete, rename, absolute, isAbsolute, state, parent)
- FileStat
- FileSystemEntityType,
- FileSystemException,

Static method (IO only)

- Directory.current
- FileSystemEntity.isFile
- FileSystemEntity.isDirectory
- FileSystemEntity.isLink

## Usage

### In memory

A simple usage example:

```dart
import 'package:fs_shim/fs_shim.dart';
import 'package:path/path.dart';

Future main() async {
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

### Using IO API

### Using fs_shim.dart

You can simply replace in the above example:

```dart
final fs = fileSystemMemory;
```

by

```dart
final fs = fileSystemIo;
```

### Using fs_io.dart

If you only target io, you can still be able to use `File` and `Directory` constructor, replace

```dart
import 'dart:io';
```

by

```dart
import 'package:fs_shim/fs_io.dart';
```


Then a reduced set of the IO API can be used, same source code that might requires some cleanup if you import from
existing code

Simple example

````
import 'dart:async';

import 'package:fs_shim/fs_io.dart';
import 'package:path/path.dart';

Future main() async {
  final fs = fileSystemIo;
  // safe place when running from package root
  final dirPath = join(Directory.current.path, 'test_out', 'example', 'dir');

  // Create a top level directory
  // fs.directory('/dir');
  final dir = Directory(dirPath);
  print('dir: $dir');
  // delete its content
  if (await dir.exists()) {
    await dir.delete(recursive: true);
  }

  // and a file in it
  // fs.file(join(dir.path, "file"));
  final file = File(join(dir.path, 'file'));

  // create a file
  await file.create(recursive: true);
  await file.writeAsString('Hello world!');

  // read a file
  print('file: ${await file.readAsString()}');

  // use a file link if supported
  if (fs.supportsFileLink) {
    // fs.newLink(join(dir.path, "link"));
    final link = Link(join(dir.path, 'link'));
    await link.create(file.path);

    print('link: ${await File(link.path).readAsString()}');
  }

  // list dir content
  print(await dir.list(recursive: true, followLinks: true).toList());
}
````

### Browser usage

You can simply replace in the in memory example:

```dart
final fs = fileSystemMemory;
```

by

```dart
final fs = fileSystemWeb;
```

### Utilities

* Lightweight glob support (`**`, `*` and `?` in a posix style path)
* Copy utilities (copy files, directories recursively)

## Testing

### Dev dependencies

Stable

    fs_shim: any

Bleeding age

    fs_shim:
        git: git://github.com/tekartik/fs_shim.dart

## Features and bugs

* On windows file links are not supported (fs.supportsFileLink returns false)
* On windows directory link target are absolutes
* On the web, the size of the file system is limited by the limit size of indexedDB databases (browser dependent)

