# tekartik_fs_shim

A portable file system library to allow working on io and browser (though idb_shim) and memory (through idb_shim), 
and soon google storage (through storage api), google drive (through google drive api)

## Usage

A simple usage example:

    import 'package:tekartik_fs_shim/fs.dart';

    main() async {
      FileSystem fs = new MemoryFileSystem();
      Directory dir = fs.newDirectory("dummy");
      await dir.create();
    }

## Features and bugs

