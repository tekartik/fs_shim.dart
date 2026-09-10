---
name: fs-shim-platforms
description: >-
  Use when choosing, configuring or testing the fs_shim FileSystem for a
  platform: fileSystemDefault vs fileSystemIo vs fileSystemMemory vs
  fileSystemWeb (IndexedDB, newFileSystemWeb, getFileSystemWeb,
  FileSystemIdbOptions page size) vs fileSystemOpfsWeb (OPFS,
  FileSystemOpfsWeb.withRootHandle, withFileHandles, showDirectoryPicker,
  showOpenFilePicker, requestWritePermission), the fs_io.dart drop-in import
  for dart:io code with wrapIoFile/unwrapIoFile, newFileSystemIdb on a sembast
  factory for persistent VM storage, and unit tests with newFileSystemMemory
  or a sandboxed io directory.
---

# fs_shim: picking a file system per platform

Every implementation is a `FileSystem`; application code should depend on
that interface and receive the instance from the platform layer. All the
entry points are safe to **import** everywhere; only **accessing** an instance
on the wrong platform throws `UnimplementedError`.

| Instance | Import | Platform | Root / paths | Links | Random access |
|---|---|---|---|---|---|
| `fileSystemDefault` | `fs_shim.dart` | all | io or web below | | |
| `fileSystemIo` | `fs_shim.dart`, `fs_io.dart` | VM, Flutter native | process cwd, native style | yes (file links not on Windows) | yes |
| `fileSystemMemory`, `newFileSystemMemory()` | `fs_shim.dart`, `fs_memory.dart` | all | `/`, posix | yes | yes |
| `fileSystemWeb`, `newFileSystemWeb`, `getFileSystemWeb` | `fs_browser.dart` | web (IndexedDB via idb_shim) | `/`, posix | yes | yes (page size opt-in) |
| `fileSystemOpfsWeb`, `FileSystemOpfsWeb.withRootHandle/withFileHandles` | `fs_opfs_web.dart` | web (OPFS, wasm ready) | `/`, posix | no | no |

```dart
import 'package:fs_shim/fs_shim.dart';

// io on the VM/Flutter native, IndexedDB in the browser.
final FileSystem fs = fileSystemDefault;
```

## Guidelines

### Default and injection

* `fileSystemDefault` is a plain top-level variable initialised to
  `fileSystemWeb` on the web and `fileSystemIo` elsewhere. It backs the
  `File()`, `Directory()`, `Link()` constructors, `Directory.current` and the
  `FileSystemEntity.isFile/isDirectory/isLink/type` statics. It can be
  reassigned (for example to `newFileSystemMemory()` in a test) and every
  constructor-based call follows.
* Prefer passing a `FileSystem` explicitly; keep the choice of implementation
  in one place (`main`, a provider, a `setUp`).
* No conditional import is needed to pick between io and a web file system at
  runtime: read `const bool.fromEnvironment('dart.library.js_interop')` (or
  Flutter's `kIsWeb`) and reference the wanted getter lazily.

### io (VM and Flutter native)

* `fileSystemIo` wraps `dart:io`; `fs.name == 'io'`, `fs.path` is the native
  `package:path` context, `currentDirectory` is the process working directory,
  `supportsFileLink` is `false` on Windows.
* To port existing `dart:io` code, replace `import 'dart:io';` with
  `import 'package:fs_shim/fs_io.dart';`. It re-exports `dart:io` except
  `File`, `Directory`, `Link`, `FileSystemEntity`, `FileSystemEntityType`,
  `FileMode`, `FileSystemException`, `FileStat` and `OSError`, which come from
  fs_shim, and adds `fileSystemIo`. Only the async subset compiles; drop
  `...Sync` calls and `Platform`-independent code keeps working.
* Bridge objects with `wrapIoFile(io.File)`, `unwrapIoFile(File)`,
  `wrapIoDirectory`/`unwrapIoDirectory`, `wrapIoLink`/`unwrapIoLink`,
  `wrapIoFileStat`, `wrapIoFileMode`, `wrapIoFileSystemEntityType`,
  `wrapIoFileSystemException` and their `unwrap*` counterparts. `unwrap*`
  casts, so it only accepts entities created by `fileSystemIo`.
* `dart:io`-typed helpers: `package:fs_shim/utils/io/copy.dart`
  (`copyDirectory`, `copyFile`, `copyDirectoryListFiles`, `deleteDirectory`,
  `deleteFile` on `io.Directory`/`io.File`), `utils/io/read_write.dart`
  (`writeString`, `writeLines`, `writeBytes`, `readString`, `readLines`,
  `dir.emptyOrCreate()`, `file.readLines()`/`file.writeLines()` extensions)
  and `utils/io/entity.dart` (`childFile`, `asDirectory`, `entityExists`...).

### Memory

* `fileSystemMemory` is a process-wide instance; `newFileSystemMemory([name])`
  (from `package:fs_shim/fs_memory.dart`) creates an isolated one. Use a new
  instance per test. `fs.name` is `'idb'` because it runs the IndexedDB
  implementation on an in-memory `idb_shim`/sembast factory.
* Posix paths rooted at `/`; `currentDirectory` is `/`; links and random
  access are supported, so it can exercise every code path of the web
  implementation on the VM.
* Content is lost when the isolate ends. For a persistent single-file store
  on the VM, build the same implementation on sembast io:
  `newFileSystemIdb(getIdbFactorySembastIo(dirPath), 'name.db')` with
  `package:fs_shim/fs_idb.dart` and `package:idb_shim/idb_io.dart` (add
  `idb_shim` to `dependencies`).

### Web on IndexedDB (`package:fs_shim/fs_browser.dart`)

* `fileSystemWeb` uses the database `lfs.db` without paging: efficient for
  whole-file `readAsString`/`writeAsString`, slow for random access and
  partial streaming.
* `getFileSystemWeb(options: FileSystemIdbOptions.pageDefault)` returns the
  same database with 16 KiB pages (`options` `null` also means 16 KiB).
  `newFileSystemWeb(name: 'other.db', options: ...)` opens a separate
  database. `fs.withIdbOptions(options:)` re-wraps an idb file system;
  `fs.idbOptions` and `fs.hasIdbOptions` inspect it.
* `FileSystemIdbOptions(pageSize:)`, `FileSystemIdbOptions.noPage`,
  `FileSystemIdbOptions.pageDefault` (16 KiB). Existing data stays readable
  when the page size changes; files are converted when next written.
* Storage is bounded by the browser IndexedDB quota. `fs_html.dart`,
  `fileSystemIdb`, `newIdbFileSystem` and `newMemoryFileSystem` are
  deprecated aliases.

### Web on OPFS (`package:fs_shim/fs_opfs_web.dart`)

* `fileSystemOpfsWeb` is the shared Origin Private File System of the page
  (`navigator.storage.getDirectory()`), `fs.name == 'opfs'`. Best for large or
  binary files. `supportsLink`, `supportsFileLink` and `supportsRandomAccess`
  are `false`; `file.open()` throws `UnsupportedError`.
* `FileSystemOpfsWeb.withRootHandle(handle)` roots a file system at a JS
  `FileSystemDirectoryHandle` obtained from
  `FileSystemOpfsWeb.showDirectoryPicker([options])` or
  `FileSystemOpfsWeb.storageGetDirectory()`.
  `FileSystemOpfsWeb.withFileHandles(handles)` exposes the files picked with
  `showOpenFilePicker`/`showSaveFilePicker` at `/<name>`; that tree is fixed
  (no create, delete, rename or mkdir).
* Pickers are Chromium-only and must run from a user gesture; they throw when
  cancelled. Handles from `showOpenFilePicker` are read-only until
  `FileSystemOpfsWeb.requestWritePermission(handle)` returns `true`; ask
  `mode: FileSystemOpfsWebShowDirectoryPickerOptions.modeReadWrite` for a
  writable directory. Handles do not survive a reload unless the app persists
  them itself.
* Options: `FileSystemOpfsWebShowDirectoryPickerOptions({id, mode, startIn})`,
  `FileSystemOpfsWebShowOpenFilePickerOptions({id, startIn, multiple,
  excludeAcceptAllOption, types})`,
  `FileSystemOpfsWebShowSaveFilePickerOptions({id, startIn, suggestedName,
  excludeAcceptAllOption, types})` with
  `FileSystemOpfsWebFilePickerAcceptType({description, accept})`.

### Testing

* Write the code under test against `FileSystem`, then run it on
  `newFileSystemMemory()` in `setUp`. Run the same `group` against several
  file systems (memory, `fileSystemIo.sandbox(path: ...)`) to catch platform
  differences; the sandbox gives io the same `/`-rooted view as the web.
* Code that uses `File()`/`Directory()` constructors is tested by assigning
  `fileSystemDefault = newFileSystemMemory()` in `setUp` and restoring it in
  `tearDown`.
* Seed fixtures with `copyDirectory` (`package:fs_shim/utils/copy.dart`) from
  `fileSystemIo` into the memory file system, or snapshot/restore any file
  system with `fsIdbExportLines`/`fsIdbImport`
  (`package:fs_shim/utils/import_export.dart`).

## Examples

### Pick the implementation at runtime

```dart
import 'package:fs_shim/fs_opfs_web.dart';
import 'package:fs_shim/fs_shim.dart';

const _isWeb = bool.fromEnvironment('dart.library.js_interop');

/// OPFS in the browser, io elsewhere. Both getters are only touched on
/// their own platform.
FileSystem get appFileSystem => _isWeb ? fileSystemOpfsWeb : fileSystemIo;
```

### Drop-in replacement for dart:io code

```dart
import 'package:fs_shim/fs_io.dart';
import 'package:path/path.dart';

Future<void> main() async {
  final dir = Directory(join(Directory.current.path, '.dart_tool', 'out'));
  await dir.create(recursive: true);
  final file = File(join(dir.path, 'hello.txt'));
  await file.writeAsString('Hello');
  print(await file.readAsString());
  // Still dart:io:
  print(Platform.operatingSystem);
}
```

### Bridge existing dart:io objects

```dart
import 'dart:io' as io;

import 'package:fs_shim/fs_io.dart';
import 'package:fs_shim/utils/read_write.dart';

Future<List<String>> linesOf(io.File ioFile) => readLines(wrapIoFile(ioFile));

io.Directory nativeDir(Directory dir) => unwrapIoDirectory(dir);
```

### Web: IndexedDB with paging and a dedicated database

```dart
import 'package:fs_shim/fs_browser.dart';

// Default database, 16 KiB pages (good for openRead/open).
final FileSystem pagedFs = getFileSystemWeb(
  options: FileSystemIdbOptions.pageDefault,
);

// Separate database with a custom page size.
final FileSystem cacheFs = newFileSystemWeb(
  name: 'cache.db',
  options: const FileSystemIdbOptions(pageSize: 64 * 1024),
);
```

### Web: OPFS and the File System Access pickers

```dart
import 'package:fs_shim/fs_opfs_web.dart';

Future<void> saveToOpfs(String name, String content) async {
  final file = fileSystemOpfsWeb.file('/data/$name');
  await file.create(recursive: true);
  await file.writeAsString(content);
}

/// Must be called from a click handler (Chromium only).
Future<FileSystem> pickProjectDirectory() async {
  final handle = await FileSystemOpfsWeb.showDirectoryPicker(
    const FileSystemOpfsWebShowDirectoryPickerOptions(
      id: 'project',
      mode: FileSystemOpfsWebShowDirectoryPickerOptions.modeReadWrite,
    ),
  );
  return FileSystemOpfsWeb.withRootHandle(handle);
}

Future<FileSystem> pickTextFiles() async {
  final handles = await FileSystemOpfsWeb.showOpenFilePicker(
    const FileSystemOpfsWebShowOpenFilePickerOptions(
      multiple: true,
      types: [
        FileSystemOpfsWebFilePickerAcceptType(
          description: 'Text',
          accept: {
            'text/plain': ['.txt', '.md'],
          },
        ),
      ],
    ),
  );
  for (final handle in handles) {
    await FileSystemOpfsWeb.requestWritePermission(handle);
  }
  return FileSystemOpfsWeb.withFileHandles(handles);
}
```

### VM: persistent IndexedDB-style file system on sembast

```dart
import 'package:fs_shim/fs_idb.dart';
import 'package:idb_shim/idb_io.dart';

/// Single-file storage under `.local/fs`, same semantics as fileSystemWeb.
final FileSystem persistentFs = newFileSystemIdb(
  getIdbFactorySembastIo('.local/fs'),
  'app.db',
);
```

### Test with a fresh memory file system

```dart
import 'package:fs_shim/fs_memory.dart';
import 'package:test/test.dart';

Future<int> countWords(File file) async =>
    (await file.readAsString()).split(RegExp(r'\s+')).length;

void main() {
  late FileSystem fs;
  setUp(() {
    fs = newFileSystemMemory();
  });
  test('countWords', () async {
    final file = fs.file('/doc.txt');
    await file.writeAsString('one two three');
    expect(await countWords(file), 3);
  });
}
```

### Run one test group on several file systems

```dart
import 'package:fs_shim/fs_memory.dart';
import 'package:fs_shim/fs_shim.dart';
import 'package:test/test.dart';

void defineTests(FileSystem fs) {
  group(fs.name, () {
    test('roundtrip', () async {
      final dir = fs.directory('/roundtrip');
      await dir.create(recursive: true);
      final file = dir.file('a.txt');
      await file.writeAsString('x');
      expect(await file.readAsString(), 'x');
      await dir.delete(recursive: true);
    });
  });
}

void main() {
  defineTests(newFileSystemMemory());
  defineTests(fileSystemIo.sandbox(path: '.dart_tool/fs_shim_test'));
}
```

### Redirect the global constructors in tests

```dart
import 'package:fs_shim/fs_memory.dart';
import 'package:fs_shim/fs_shim.dart';
import 'package:test/test.dart';

Future<bool> hasConfig() => File('/config.json').exists();

void main() {
  late FileSystem saved;
  setUp(() {
    saved = fileSystemDefault;
    fileSystemDefault = newFileSystemMemory();
  });
  tearDown(() {
    fileSystemDefault = saved;
  });
  test('missing then present', () async {
    expect(await hasConfig(), isFalse);
    await File('/config.json').writeAsString('{}');
    expect(await hasConfig(), isTrue);
  });
}
```

## Common mistakes

* Importing `dart:io` and `package:fs_shim/fs_shim.dart` together: use
  `fs_io.dart`, or `import 'dart:io' as io;`.
* Using `fileSystemWeb`/`fileSystemOpfsWeb` in VM tests: they throw
  `UnimplementedError`; test on `newFileSystemMemory()`.
* Sharing `fileSystemMemory` across tests and depending on a clean state.
* Expecting random access or links on OPFS, or file links on Windows.
* Passing `dart:io` entities to fs_shim helpers without `wrapIoFile`/
  `wrapIoDirectory`, or the io helpers from `utils/io/...` to fs_shim ones.
* Calling the OPFS pickers outside a user gesture or on a non-Chromium
  browser.
