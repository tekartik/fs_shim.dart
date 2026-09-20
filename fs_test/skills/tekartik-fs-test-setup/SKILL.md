---
name: tekartik-fs-test-setup
description: >-
  Use when running the shared fs_shim conformance test suite against a
  FileSystem implementation with tekartik_fs_test: defineFsTests / defineTests
  from package:tekartik_fs_test/fs_test.dart, the FileSystemTestContext
  contract (fs, platform, basePath, prepare()), FileSystemTestContextMixin,
  memoryFileSystemTestContext, MemoryFileSystemTestContextWithOptions,
  IdbFileSystemTestContext, FileSystemTestContextIdbWithOptions,
  FileSystemTestContextIdbWeb, ctx.sandbox(path:), platformContextIo /
  platformContextBrowser, isIo / isIoWindows guards, fsPerfTestGroup, and the
  package:tekartik_fs_test/test_common.dart re-exports.
---

# tekartik_fs_test: the shared fs_shim test suite (tekartik_fs_test)

`tekartik_fs_test` packages the whole `fs_shim` conformance suite (directories,
files, links, stat, exceptions, random access, sandboxing, import/export and
the `utils/` helpers) behind one call, `defineFsTests(ctx)`. Any `FileSystem`
implementation — io, memory, IndexedDB, OPFS or your own — is validated by
providing a `FileSystemTestContext`.

## Guidelines

* Dev dependency (git, not on pub.dev); add `test` too, the suite is written
  with `package:dev_test/test.dart`, a superset of `package:test`:
  ```yaml
  dev_dependencies:
    test: ">=1.31.0"
    tekartik_fs_test:
      git:
        url: https://github.com/tekartik/fs_shim.dart
        path: fs_test
      version: '>=0.1.0'
  ```
* Two imports cover most needs:
  * `package:tekartik_fs_test/fs_test.dart` — `defineFsTests(ctx)`, the older
    alias `defineTests(ctx)`, and it re-exports `package:fs_shim/fs.dart` and
    `fs_test_common.dart` (the contexts).
  * `package:tekartik_fs_test/test_common.dart` — the contexts plus
    `dart:async`, `dart:convert`, `package:fs_shim/fs.dart`, the `fs_shim`
    helpers (`utils/copy.dart`, `entity.dart`, `glob.dart`, `part.dart`,
    `path.dart`, `read_write.dart`), the platform contexts, `FileSystemIdb`,
    `debugIdbShowLogs`, and `devPrint` / `isRunningAsJavascript` /
    `kDartIsWeb` from `tekartik_common_utils`.
* A `FileSystemTestContext` provides `fs` (the file system under test),
  `platform` (a `PlatformContext?`), `basePath`/`baseDir`, `path` (the
  `package:path` `Context` of `fs`), `supportsFileContentStream` and
  `prepare()`. Implement it by mixing in `FileSystemTestContextMixin`: only
  `fs` and `platform` are then left to define, and `basePath` is a settable
  field (set it in the constructor, e.g. under `.dart_tool` on io).
* `await ctx.prepare()` returns a freshly emptied `Directory` — a new numbered
  sub-directory of `basePath` on every call. Call it at the beginning of each
  test that needs files; never reuse a directory between tests.
* Ready made contexts:
  * `memoryFileSystemTestContext` (shared) and `MemoryFileSystemTestContext()`
    — in-memory, works on every platform, the default smoke test.
  * `MemoryFileSystemTestContextWithOptions(options: ...)` — memory with a
    given `FileSystemIdbOptions` page size.
  * `IdbFileSystemTestContext` / `FileSystemTestContextIdbWithOptions` —
    base classes for an IndexedDB based file system: override `rawFsIdb`
    (a `FileSystemIdb`), the context applies `options` to it.
  * `FileSystemTestContextIdbWeb(options: ...)` from
    `package:tekartik_fs_test/fs_test_web.dart` — the browser IndexedDB file
    system, for `@TestOn('browser')` tests.
* `ctx.sandbox(path: '/root')` (extension on `FileSystemTestContext`) returns a
  context over `fs.sandbox(path:)`, so the whole suite can be re-run on a
  sandboxed file system; sandboxes can be nested.
* Platform: `platformContextIo` (`package:tekartik_fs_test/test_common.dart`,
  throws `UnsupportedError` on the web) and `platformContextBrowser` (throws on
  io) fill `ctx.platform`; a context can also leave it `null`. Guard
  expectations with `isIo(ctx)`, `isIoWindows(ctx)`, `isIoMac(ctx)`,
  `isIoLinux(ctx)` and `isIoNode(ctx)` rather than with `Platform` directly, so
  the same test file compiles on the web.
* Sub-suites, when the full `defineFsTests` is too much: import the individual
  libraries with a prefix — `fs_shim_dir_test.dart`, `fs_shim_file_test.dart`,
  `fs_shim_link_test.dart`, `fs_shim_file_stat_test.dart`,
  `fs_shim_file_system_test.dart`, `fs_shim_file_system_exception_test.dart`,
  `fs_shim_random_access_file_test.dart`, `fs_shim_sanity_test.dart` and
  `utils_test.dart` all expose `defineTests(FileSystemTestContext)`;
  `fs_shim_file_system_sandbox_test.dart` exposes
  `defineFileSystemSandboxTests`, `fs_file_system_entity_parent_test.dart`
  `defineFileSystemEntityParentTests`, `fs_import_export_test.dart`
  `defineImportExportTests`, and `fs_current_dir_file_test.dart` a
  `defineTests(FileSystem)` (no context).
* Benchmarks: `fsPerfTestGroup(fs, {params})` from
  `package:tekartik_fs_test/fs_perf_test.dart` times writes and reads for a
  list of `FsPerfParam(count, size)`; `fsPerfMarkdownResult()` in a
  `tearDownAll` prints the comparison table of every file system measured.
* Running: `dart test` for VM contexts (`@TestOn('vm')`),
  `dart test -p chrome` or `dart run build_runner test -- -p chrome test/web`
  for browser contexts (`@TestOn('browser')`, needs `build_test` and
  `build_web_compilers`). The suite writes real files, so keep io `basePath`
  inside `.dart_tool`.
* Do not write assertions against the internals of a context; keep your own
  tests in separate `defineTests(FileSystemTestContext ctx)` functions so the
  same file runs on memory, io and browser contexts.

## Examples

### Smoke test on the memory file system

```dart
import 'package:tekartik_fs_test/fs_test.dart';
import 'package:test/test.dart';

void main() {
  group('memory', () {
    defineFsTests(memoryFileSystemTestContext);
    group('sandbox', () {
      defineFsTests(memoryFileSystemTestContext.sandbox(path: '/root'));
    });
  });
}
```

### Context for a dart:io file system

```dart
@TestOn('vm')
library;

import 'package:fs_shim/fs_shim.dart';
import 'package:path/path.dart';
import 'package:tekartik_fs_test/fs_test.dart';
import 'package:tekartik_fs_test/test_common.dart';
import 'package:test/test.dart';

class FileSystemTestContextIo extends FileSystemTestContext
    with FileSystemTestContextMixin {
  @override
  final FileSystem fs = fileSystemIo;
  @override
  final PlatformContext platform = platformContextIo;

  FileSystemTestContextIo() {
    basePath = join('.dart_tool', 'my_package', 'test');
  }
}

void main() {
  group('io', () => defineFsTests(FileSystemTestContextIo()));
}
```

### Context for your own FileSystem implementation

```dart
import 'package:fs_shim/fs_memory.dart';
import 'package:tekartik_fs_test/fs_test.dart';
import 'package:tekartik_fs_test/test_common.dart';
import 'package:test/test.dart';

/// Replace by the file system under test.
FileSystem newMyFileSystem() => newFileSystemMemory();

class MyFileSystemTestContext extends FileSystemTestContext
    with FileSystemTestContextMixin {
  @override
  final FileSystem fs = newMyFileSystem();
  @override
  PlatformContext? platform;

  /// Set to false if openRead/openWrite are not supported.
  @override
  bool get supportsFileContentStream => true;

  MyFileSystemTestContext() {
    basePath = '/test';
  }
}

void main() {
  group('my_fs', () => defineFsTests(MyFileSystemTestContext()));
}
```

### Idb based implementation, one run per page size

```dart
import 'package:fs_shim/fs_idb.dart';
import 'package:fs_shim/fs_memory.dart';
import 'package:tekartik_fs_test/fs_test.dart';
import 'package:tekartik_fs_test/test_common.dart';
import 'package:test/test.dart';

class MyIdbFileSystemTestContext extends FileSystemTestContextIdbWithOptions {
  MyIdbFileSystemTestContext({required super.options});

  @override
  late final FileSystemIdb rawFsIdb = newFileSystemMemory() as FileSystemIdb;
}

void main() {
  for (final options in [
    FileSystemIdbOptions.noPage,
    FileSystemIdbOptions.pageDefault,
    const FileSystemIdbOptions(pageSize: 2),
  ]) {
    group('idb_${options.pageSize}', () {
      defineFsTests(MyIdbFileSystemTestContext(options: options));
    });
  }
}
```

### Your own tests on top of a context, with platform guards

```dart
import 'package:tekartik_fs_test/fs_shim_dir_test.dart' as dir_test;
import 'package:tekartik_fs_test/fs_test.dart';
import 'package:tekartik_fs_test/test_common.dart';
import 'package:test/test.dart';

void defineAppTests(FileSystemTestContext ctx) {
  group('app', () {
    test('write and read back', () async {
      final dir = await ctx.prepare(); // fresh empty directory
      final file = dir.file('data.txt');
      await file.writeAsString('hello');
      expect(await file.readAsString(), 'hello');
    });
    test('link', () async {
      if (!ctx.fs.supportsLink) {
        return;
      }
      final dir = await ctx.prepare();
      final target = dir.directory('target');
      await target.create();
      await dir.link('to_target').create(target.path);
      expect(await dir.directory('to_target').exists(), isTrue);
    }, skip: isIoWindows(ctx) ? 'no file link on windows' : null);
  });
}

void main() {
  final ctx = memoryFileSystemTestContext;
  dir_test.defineTests(ctx); // just the directory suite
  defineAppTests(ctx);
}
```

### Benchmark two file systems

```dart
import 'package:fs_shim/fs_memory.dart';
import 'package:tekartik_fs_test/fs_perf_test.dart';
import 'package:tekartik_fs_test/test_common.dart';
import 'package:test/test.dart';

void main() {
  fsPerfTestGroup(
    newFileSystemMemory(),
    params: [FsPerfParam(100, 1024), FsPerfParam(5, 1024 * 1024)],
  );
  tearDownAll(() {
    // ignore: avoid_print
    print(fsPerfMarkdownResult());
  });
}
```

## Common mistakes

* Sharing one prepared directory between tests instead of calling
  `ctx.prepare()` in each test.
* Using `platformContextIo` in a test that also runs on the browser (it
  throws): leave `platform` null or pick it per platform.
* Testing `Platform.isWindows` directly instead of `isIoWindows(ctx)`.
* Forgetting `@TestOn('vm')` / `@TestOn('browser')` on a context that only
  exists on one platform.
* Declaring `tekartik_fs_test` in `dependencies`: it belongs in
  `dev_dependencies`.
