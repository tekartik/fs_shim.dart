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

    import 'package:tekartik_fs_shim/fs_memory.dart';

    main() async {
      FileSystem fs = newMemoryFileSystem();
      Directory dir = fs.newDirectory("dummy");
      await dir.create();
    }

### Using IO API

Replace

    import 'dart:io';

with

    import 'package:fs_shim/fs_io.dart';

Then a reduced set of the IO API can be used, same source code that might requires some cleanup if you import from
existing code

### Utilities

* Lightweight glob support (`**`, `*` and `?` in a posix style path)
* Copy classes (alpha)

## Features and bugs

* On windows file link are not supported (fs.supportsFileLink returns false)
* On windows directory link target are absolutes

