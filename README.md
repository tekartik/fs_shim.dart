# fs_shim

A portable file system library to allow working on io and browser (though idb_shim) and memory (through idb_shim), 
and soon google storage (through storage api), google drive (through google drive api)

[![Build Status](https://travis-ci.org/tekartik/fs_shim.dart.svg?branch=master)](https://travis-ci.org/tekartik/fs_shim.dart)

## API supported

Classes

- File (create, openWrite, openRead, writeAsBytes, writeAsString, copy)
- Link (create, target)
- Directory (create, list)
- FileSystem (newDirectory, newFile, newLink, type, isFile, isDirectory, isLink)
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

````
import 'package:fs_shim/fs.dart';
import 'package:fs_shim/fs_memory.dart';
import 'package:path/path.dart';

main() async {
  FileSystem fs = newMemoryFileSystem();

  // Create a top level directory
  Directory dir = fs.newDirectory('/dir');

  // and a file in it
  File file = fs.newFile(join(dir.path, "file"));

  // create a file
  await file.create(recursive: true);
  await file.writeAsString("Hello world!");

  // read a file
  print('file: ${await file.readAsString()}');

  // use a file link if supported
  if (fs.supportsFileLink) {
    Link link = fs.newLink(join(dir.path, "link"));
    await link.create(file.path);

    print('link: ${await fs.newFile(link.path).readAsString()}');
  }

  // list dir content
  print(await dir.list(recursive: true, followLinks: true).toList());
}
````

### Using IO API

Replace

    import 'dart:io';

with

    import 'package:fs_shim/fs_io.dart';

Then a reduced set of the IO API can be used, same source code that might requires some cleanup if you import from
existing code

Simple example

````
import 'package:fs_shim/fs_io.dart';
import 'package:path/path.dart';

main() async {
  FileSystem fs = ioFileSystem;
  // safe place when running from package root
  String dirPath = join(Directory.current.path, 'test_out', 'example', 'dir');

  // Create a top level directory
  // fs.newDirectory('/dir');
  Directory dir = new Directory(dirPath);

  // delete its content
  await dir.delete(recursive: true);

  // and a file in it
  // fs.newFile(join(dir.path, "file"));
  File file = new File(join(dir.path, "file"));

  // create a file
  await file.create(recursive: true);
  await file.writeAsString("Hello world!");

  // read a file
  print('file: ${await file.readAsString()}');

  // use a file link if supported
  if (fs.supportsFileLink) {
    // fs.newLink(join(dir.path, "link"));
    Link link = new Link(join(dir.path, "link"));
    await link.create(file.path);

    print('link: ${await new File(link.path).readAsString()}');
  }

  // list dir content
  print(await dir.list(recursive: true, followLinks: true).toList());
}
````

### Utilities

* Lightweight glob support (`**`, `*` and `?` in a posix style path)
* Copy utilities (copy files, directories recursively)

## Testing

### Testing with dartdevc

    pub serve test --web-compiler=dartdevc --port=8079
    pub run test -p chrome --pub-serve=8079

## Features and bugs

* On windows file links are not supported (fs.supportsFileLink returns false)
* On windows directory link target are absolutes

