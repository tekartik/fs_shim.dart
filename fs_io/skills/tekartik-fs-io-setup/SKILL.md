---
name: tekartik-fs-io-setup
description: >-
  Use when a Dart VM or Flutter native app needs the dart:io backed fs_shim
  FileSystem through tekartik_fs_io: the single `fileSystem` variable of
  package:tekartik_fs_io/fs_io.dart (an alias of fs_shim's fileSystemIo), the
  git dependency block on fs_shim.dart/fs_io, why the import pulls dart:io and
  must stay out of web code, swapping it for newFileSystemMemory() in tests,
  and running the shared tekartik_fs_test suite (FileSystemTestContext,
  defineFsTests, platformContextIo, sandbox) against it.
---

# tekartik_fs_io: the io FileSystem instance (tekartik_fs_io)

`tekartik_fs_io` is a one-symbol convenience package: it exposes `fileSystem`,
a `FileSystem` (from `fs_shim`) initialised to `fileSystemIo`, the `dart:io`
implementation. Everything else — the `File`, `Directory`, `FileSystem` types
and all the helpers — comes from `fs_shim` itself.

## Guidelines

* Dependency (git, not on pub.dev). Depend on `fs_shim` too, since that is
  where the types live:
  ```yaml
  dependencies:
    fs_shim: ">=2.3.3+1"
    tekartik_fs_io:
      git:
        url: https://github.com/tekartik/fs_shim.dart
        path: fs_io
  ```
* `package:tekartik_fs_io/fs_io.dart` declares exactly one symbol,
  `FileSystem fileSystem`, and re-exports nothing. Import
  `package:fs_shim/fs_shim.dart` (or `package:fs_shim/fs.dart`) in the same
  file as soon as you name `FileSystem`, `File`, `Directory`, `FileMode`,
  `FileSystemException`...
* The import is VM/Flutter-native only: it reaches `package:fs_shim/fs_io.dart`,
  which exports `dart:io`, so a web build of a library importing it does not
  compile. Keep it in `main`, in the io half of a conditional import or in a
  `@TestOn('vm')` test; shared code should take a `FileSystem` parameter.
  `fs_shim`'s own `fileSystemDefault` (io on the VM, IndexedDB on the web) is
  the multiplatform alternative.
* `fileSystem` is a mutable top-level variable, so a test can point it at
  another implementation (`newFileSystemMemory()` from
  `package:fs_shim/fs_memory.dart`) and restore it in `tearDown`. It only
  redirects code that reads `fileSystem`; `fs_shim`'s own `File()` /
  `Directory()` constructors follow `fileSystemDefault` instead. Prefer
  injecting a `FileSystem` and using `fileSystem` once, at the entry point.
* Everything else is plain `fs_shim`: `fileSystem.file(path)`,
  `fileSystem.directory(path)`, `fileSystem.path` (a native `package:path`
  `Context`), `fileSystem.currentDirectory` (the process working directory),
  `fileSystem.name == 'io'`, `fileSystem.supportsLink` /
  `supportsFileLink` (`false` for file links on Windows) and
  `fileSystem.sandbox(path: ...)` to get a file system rooted in a
  sub-directory. Wrapping existing `dart:io` objects (`wrapIoFile`,
  `unwrapIoDirectory`, ...) needs `package:fs_shim/fs_io.dart` directly.
* `idb_shim` is a dependency of this package, so an io program can also build
  the persistent IndexedDB-style file system with `newFileSystemIdb(...)`
  (`package:fs_shim/fs_idb.dart`) over `getIdbFactorySembastIo(dirPath)`
  (`package:idb_shim/idb_io.dart`) — same semantics as the browser file
  system, on a single sembast store. Declare `idb_shim` in your own pubspec
  when you import it.
* Tests: `tekartik_fs_test` (same repo, `path: fs_test`) runs the whole
  fs_shim conformance suite against a `FileSystemTestContext`. On io, mix in
  `FileSystemTestContextMixin`, set `fs = fileSystem`, `platform =
  platformContextIo` and a `basePath` under `.dart_tool`, then call
  `defineFsTests(ctx)` (`defineTests` is the older alias). `ctx.sandbox(path:)`
  reruns the same suite in a sandboxed file system. Run with `dart test`
  (`@TestOn('vm')`).

## Examples

### Read and write with the io file system

```dart
import 'package:fs_shim/fs_shim.dart';
import 'package:tekartik_fs_io/fs_io.dart';

Future<void> main() async {
  final FileSystem fs = fileSystem; // dart:io implementation
  final dir = fs.directory(fs.path.join('.dart_tool', 'demo'));
  await dir.create(recursive: true);
  final file = fs.file(fs.path.join(dir.path, 'hello.txt'));
  await file.writeAsString('Hello');
  print(await file.readAsString());
  print('${fs.name} ${fs.currentDirectory.path}');
}
```

### Keep shared code platform free, pick io at the entry point

```dart
import 'package:fs_shim/fs_shim.dart';
import 'package:tekartik_fs_io/fs_io.dart';

/// Platform free: works on memory, io or web file systems.
Future<int> countLines(FileSystem fs, String path) async {
  final content = await fs.file(path).readAsString();
  return content.split('\n').length;
}

Future<void> main(List<String> args) async {
  print(await countLines(fileSystem, args.first));
}
```

### Sandbox a sub-directory

```dart
import 'package:fs_shim/fs_shim.dart';
import 'package:tekartik_fs_io/fs_io.dart';

/// Rooted at `.dart_tool/app_data`: '/config.json' below is
/// `.dart_tool/app_data/config.json` on disk.
final FileSystem dataFs = fileSystem.sandbox(
  path: fileSystem.path.join('.dart_tool', 'app_data'),
);

Future<void> saveConfig(String json) async {
  final file = dataFs.file('/config.json');
  await file.parent.create(recursive: true);
  await file.writeAsString(json);
}
```

### Unit test on memory, by redirecting `fileSystem`

```dart
@TestOn('vm')
library;

import 'package:fs_shim/fs_memory.dart';
import 'package:fs_shim/fs_shim.dart';
import 'package:tekartik_fs_io/fs_io.dart';
import 'package:test/test.dart';

Future<void> writeStamp() => fileSystem.file('/stamp.txt').writeAsString('ok');

void main() {
  late FileSystem saved;
  setUp(() {
    saved = fileSystem;
    fileSystem = newFileSystemMemory();
  });
  tearDown(() {
    fileSystem = saved;
  });
  test('writeStamp', () async {
    await writeStamp();
    expect(await fileSystem.file('/stamp.txt').readAsString(), 'ok');
  });
}
```

### Run the shared fs_shim conformance suite on io

```dart
@TestOn('vm')
library;

import 'package:path/path.dart';
import 'package:tekartik_fs_io/fs_io.dart';
import 'package:tekartik_fs_test/fs_test.dart';
import 'package:tekartik_fs_test/test_common.dart';
import 'package:test/test.dart';

class FileSystemTestContextIo extends FileSystemTestContext
    with FileSystemTestContextMixin {
  @override
  final PlatformContext platform = platformContextIo;
  @override
  bool get supportsFileContentStream => true;
  @override
  FileSystem fs = fileSystem;

  FileSystemTestContextIo() {
    basePath = join('.dart_tool', 'my_app', 'test');
  }
}

void main() {
  final ctx = FileSystemTestContextIo();
  group('io', () => defineFsTests(ctx));
  group('io_sandbox', () {
    defineFsTests(ctx.sandbox(path: join('.dart_tool', 'my_app', 'sandbox')));
  });
}
```

## Common mistakes

* Importing `package:tekartik_fs_io/fs_io.dart` from code that is also
  compiled for the web: it drags in `dart:io`.
* Expecting `File`/`Directory` from this package: import `fs_shim`.
* Reassigning `fileSystem` and expecting `fs_shim`'s global `File()` /
  `Directory()` constructors to follow: they use `fileSystemDefault`.
* Forgetting that relative paths resolve against the process working
  directory; write test output under `.dart_tool`.
