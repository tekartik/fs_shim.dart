## 2.7.0

* OPFS: handles can be persisted (e.g. in IndexedDB, idb_shim `IdbNativeValue` / sdb `SdbNativeValue`) and
  restored without importing `src/`:
  * `FileSystemOpfsWebFileHandle.fromJsObject()` and `FileSystemOpfsWebDirectoryHandle.fromJsObject()` wrap a
    JS handle (any interop binding).
  * `handle.jsObject` (the wrapped JS handle) and `handle.name` (also its path in `withFileHandles`), as
    extension getters (`FileSystemOpfsWebFileSystemEntityHandleExtension`).
  * `FileSystemOpfsWeb.queryPermission()` and `FileSystemOpfsWeb.requestPermission()` (`mode`: `read`, the
    default, or `readwrite`) return the permission state (`granted`, `denied` or `prompt`).
    `requestWritePermission()` is kept. Browsers without the permission API (Firefox, Safari: OPFS handles
    only) return `granted` (`requestWritePermission()` used to throw there).

## 2.6.1

* Behave like `dart:io` in these cases (bug fixes, the previous behavior lost data or hung):
  * idb: `openRead(start)` with a `start` past the first page (16 KiB pages for `getFileSystemWeb()` and
    `newFileSystemWeb()`) no longer fails with `Corrupted content`.
  * idb and OPFS: renaming a file or a directory to its own path does nothing (idb emptied the file, OPFS
    deleted it).
  * idb and OPFS: renaming a directory below itself fails with an invalid argument status (22) (idb made the
    directory unreachable, OPFS never completed).
  * idb: a file or a directory can no longer be created, written, read, copied or renamed below a file, and
    listing a file fails, with a not a directory status (20). OPFS now gives 20 instead of 2 (not found) in
    these cases.
  * idb: copying a directory (`File(dirPath).copy()`), or a directory onto a directory, fails with an is a
    directory status (21) instead of creating an empty file.
  * idb and OPFS: `openRead(start, end)` honors `end` without pages and clamps `start` and `end` past the end
    of the file (empty stream when `start` is past the end), an `end` before `start` throws a `RangeError`.
* Sandboxed file system: `writeAsString` uses the given `encoding`.
* io: Windows error codes no longer go through the Linux mapping, macOS permission errors get the access
  error status, and `osError` is null (instead of a wrapper throwing on access) when `dart:io` has none.

## 2.6.0

* idb: open a new IndexedDB connection when the browser closed the current one (`InvalidStateError` on
  every transaction), including from an open `RandomAccessFile` or write sink; a failed open now reports
  its error to the caller and is retried on the next operation; a failed read stream now completes.
  Thanks to [Samuel Hislop-Lynch (SamHL)](https://github.com/SamHL) for the fix in
  [#63](https://github.com/tekartik/fs_shim.dart/pull/63).

## 2.5.7

* Add `streamToFile(stream, file)` helper and `File.writeStream(stream)` extension in `utils/read_write.dart`
  to write a `Stream<List<int>>` to a file, creating the parent directory if missing. On a file system
  without random access support (OPFS) the stream is buffered in memory and written at once.

## 2.5.6

* Add `fs-shim-filesystem` and `fs-shim-platforms` agent skills in `skills/`, installable with `dart run skills@ get`

## 2.5.5

* Add `File.unsandbox()` and `Directory.unsandbox()` extension methods to get the full path in the delegate file system
  if any

## 2.5.4+2

* Add `FileSystemOpfsWeb.withRootHandle()` to create a file system rooted at an existing
  `FileSystemOpfsWebDirectoryHandle` (e.g. obtained from
  `FileSystemOpfsWeb.showDirectoryPicker()` or `FileSystemOpfsWeb.storageGetDirectory()`).
* Add `FileSystemOpfsWeb.withFileHandles()` to create a file system giving access to files obtained from
  `FileSystemOpfsWeb.showOpenFilePicker()`/`FileSystemOpfsWeb.showSaveFilePicker()`.
* Add `fileSystemOpfsWeb.requestWritePermission()` to request the `readwrite`
  permission on a file or directory handle
* Use conditional imports for `fileSystemDefault` so that importing
  `package:fs_shim/fs.dart` no longer pulls `dart:io` on the web (fixes the build_web_compilers platform check when
  compiling web entrypoints)

## 2.5.3

* Add `fileSystemOpfsWeb`.

## 2.5.2

* dart 3.12 and new lints

## 2.5.1+1

* Add `Directory.sandbox` extension method as shortcut to sandbox a file system
* Add `fsIdbExportLines` and `fsIdbImport` mainly for testing purpose
* Add `FileStreamSink` to add `flush` feature when writing files.
* requires dart 3.11

## 2.5.0+4

* Add `Directory.tryCreate` extension method to create a directory if it does not exist
* Add `FileSystem.sandbox` extension method to create a sandboxed file system
* Add `FileSystem.unsandbox` extension method to get the parent file system directory
* Add `FileSystem.absolutePath` extension method to get an absolute path
* Add `FileSystem.normalizePath` extension method to get an absolute path
* Add `FileSystem.pathHashCode` extension method to get a hash code for a path (normalized and absolute)
* Add `FileSystem.pathEquals` extension method to compare two paths (normalized and absolute)
* Add `FileSystemEntityParent.link` method to create a link in the parent directory
* Add `FileSystemEntityParent.childPath` method to get a child path in the parent directory/file system
* null `path` argument no longer accepted for file, directory, and link constructors and various entity path arguments
  in methods (type, isFile, isDirectory, isLink). This should be considered as a breaking change, however null was
  always throwing an error. Sorry if not ok for you...

## 2.4.0+1

* Add `FileSystemEntityParent` interface with `directory()`, `directoryWith()`, and `file()` methods for Directory and
  FileSystem
* Fix web detection

## 2.3.4

* Requires dart 3.7

## 2.3.3+1

* Add `Directory.emptyOrCreate()` helper in utils read_write (fs and io)

## 2.3.2+3

* Add writeLines/readLines and io lines helpers
* require dart 3.5

## 2.3.1+3

* Remove `dev_test` dependency
* Remove `dart:html` dependency

## 2.2.1

* Dart 3 support

## 2.2.0

* Add `fileSystemDefault` global on web and io.
* Add `File`, `Link` and `Directory`.
* Add `Directory.current`.
* Add `FileSystemEntity.isLink`, `FileSystemEntity.isFile`, `FileSystemEntity.isDirectory`,
  `FileSystemEntity.type`

## 2.1.0+2

* RandomAccessFile support
* strict-casts support

## 2.0.3

* add toNativePath is `utils/path.dart`

## 2.0.2+3

* dart 2.14 lints
* fix toPosixPath to handle proper conversion of windows drive letter

## 2.0.1+2

* Idb file system now always uses `/` separator even on idb io windows (never used).

## 2.0.0

* `nnbd` supports, breaking change.

## 1.0.2+3

* Fix executable flag when copying on io
* Save binary as blob instead of List<int> on indexeddb
* Support larger file on the web (slow though)

## 1.0.0+1

* Make `fs_shim.dart` import work on both io and web
* First stable release

## 0.12.0

* copy utils cleanup

## 0.11.2

* Pedantic 1.9 support

## 0.11.0+3

* Sdk 2.5 support

## 0.10.0

* deprecate ewFile, newDirectory, newLink, pathContext

## 0.9.0

* dart2 only

## 0.8.2

* add file, directory and link to replace newFile, newDirectory, newLink

## 0.7.3

* Add support `implicit-cast: false`

## 0.7.2

* Add `deleteFile`, `deleteDirectory`

## 0.7.1

Add io, deleteFile and deleteDirectory io helpers

## 0.6.6

Add copyDirectoryListFiles

## 0.6.5

Add copy io utils. Support including files

## 0.6.4

Add read_write io utils

## 0.6.3

Add io entity utils

## 0.6.0

Add copy utilities:

- copyDirectory
- copyFile
- createDirectory
- createFile
- deleteDirectory
- deleteFile

## 0.5.0

Add support for links in Directory.list

## 0.2.0

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

