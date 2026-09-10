# fs_shim utilities and building blocks

All helpers take fs_shim entities (`File`, `Directory` from
`package:fs_shim/fs_shim.dart`). For the same helpers on `dart:io` types see
`package:fs_shim/utils/io/copy.dart`, `utils/io/read_write.dart` and
`utils/io/entity.dart` (documented in the `fs-shim-platforms` skill).

## Copy (`package:fs_shim/utils/copy.dart`)

```dart
Future<Directory> copyDirectory(Directory src, Directory? dst, {CopyOptions? options});
Future<File> copyFile(File src, File dst, {CopyOptions? options});
Future<List<File>> copyDirectoryListFiles(Directory src, {CopyOptions? options});
Future deleteDirectory(Directory dir, {DeleteOptions? options});
Future deleteFile(File file, {DeleteOptions? options});
Future<Directory> createDirectory(Directory dir, {CreateOptions? options});
Future<File> createFile(File file, {CreateOptions? options});
```

* `src` and `dst` can belong to different file systems (io to memory, memory
  to web...). Content is streamed, then `copyFileMeta` copies the executable
  bit when the target file supports it.
* `copyDirectory` throws `ArgumentError` when `src` is not a directory and
  returns `dst`. `copyDirectoryListFiles` runs the same include/exclude walk
  without copying and returns the source files that would be copied.
* `deleteDirectory`/`deleteFile` ignore a missing entity and print other
  errors instead of throwing; `DeleteOptions.create` recreates the entity
  afterwards.

### `CopyOptions`

| Field | Default | Effect |
|---|---|---|
| `recursive` | `false` | Descend into sub directories. `defaultCopyOptions` sets it to `true`. |
| `checkSizeAndModifiedDate` | `false` | Skip a file whose destination has the same size and is not older. |
| `tryToLinkFile` | `false` | On the same file system with `supportsFileLink`, create a link to the source instead of copying. |
| `tryToLinkDir` | `false` | Reserved, not implemented. |
| `followLinks` | `true` | Follow links while walking `src`; when `false` links are skipped. |
| `delete` | `false` | Delete `dst` before copying. |
| `include` | `null` | Globs; when set only matching files (and directories ending with `/`) are copied. |
| `exclude` | `null` | Globs of files/directories to skip. |
| `verbose` | `false` | Print every operation. |

Presets: `defaultCopyOptions` (recursive), `copyNewerOptions`
(`checkSizeAndModifiedDate`, not recursive), `recursiveLinkOrCopyNewerOptions`
(recursive + newer check + `tryToLinkFile`), `defaultCloneOptions`
(`tryToLinkFile`). `options.copyWith(...)` and `options.clone` derive new
options.

`CreateOptions` has `recursive` (default `true`) and `delete`;
`defaultCreateOptions` is recursive. `DeleteOptions` has `recursive` (default
`true`), `followLinks` and `create`; `defaultDeleteOptions` is recursive.

### Include / exclude globs

* Patterns are matched against the path relative to `src`, split on `/` or
  `\`, so write them posix style (`'lib/**/*.g.dart'`).
* A pattern ending with `/` (`Glob.isDir`) applies to directories; other
  patterns apply to files. `exclude: ['.dart_tool/']` prunes the whole tree,
  `exclude: ['*.log']` skips matching files anywhere they match.
* With `include`, a matching directory pattern includes the whole sub tree
  (the include rules are dropped below it); file patterns include single
  files.

## Glob (`package:fs_shim/utils/glob.dart`)

`Glob(expression)`:

* `*` matches zero or more characters inside one path segment, `?` exactly
  one character, `**` alone in a segment matches zero or more directories.
* `matches(path)` splits the path (posix or windows separators) and returns
  `false` on an empty path instead of throwing; `matchesParts(List<String>)`
  takes pre-split segments.
* No `{a,b}` alternation, no `[abc]` classes, no negation.

## Path conversion (`package:fs_shim/utils/path.dart`)

* `toPosixPath(any)`: `\a\b` becomes `/a/b`, `C:\x` becomes `/C:/x`.
* `toWindowsPath(any)`: `/a/b` becomes `\a\b`, `/C:/x` becomes `C:\x`.
* `toNativePath(any)` converts to the current `package:path` context (use
  before handing a posix path to `fileSystemIo` on Windows).
* `toContextPath(context, any)` and `contextPathSplit(context, path)` for an
  explicit `Context`; `isPathPartSeparator(part)`.

## Entity helpers (`package:fs_shim/utils/entity.dart`)

* `childFile(dir, 'name')`, `childDirectory(dir, 'name')`,
  `childLink(dir, 'name')` join with `dir.fs.path`.
* `asFile(entity)`, `asDirectory(entity)`, `asLink(entity)` re-type an entity
  of another kind at the same path.
* `entityExists(entity)` is true for any entity type at that path, unlike
  `entity.exists()` which also checks the type.

## Read/write (`package:fs_shim/utils/read_write.dart`)

* `writeString(file, text, {encoding})`, `writeBytes(file, Uint8List)`,
  `writeLines(file, lines, {encoding, useCrLf})`: write with `flush: true`;
  if the write fails, create `file.parent` recursively and retry.
  `useCrLf` defaults to `true` on Windows io only.
* `readString(file, {encoding})`, `readLines(file, {encoding})` (uses
  `LineSplitter`, so `\n` and `\r\n` both work).
* `extension DirectoryEmptyOrCreateExt on Directory { emptyOrCreate() }`.

## Snapshots (`package:fs_shim/utils/import_export.dart`)

* `Future<List<Object>> fsIdbExportLines(FileSystem fs)` exports the content
  of any file system (non-idb file systems are first copied into a memory
  file system) as JSON-compatible lines.
* `Future<void> fsIdbImport(FileSystem fs, Object data)` copies an export into
  `fs.currentDirectory`. Useful for test fixtures and debugging.

## Implementing a FileSystem (`package:fs_shim/fs_mixin.dart`)

`FileSystemMixin`, `FileSystemEntityMixin`, `FileMixin`, `DirectoryMixin`,
`LinkMixin` provide default `==`/`hashCode`/`toString`, `isFile`/`isDirectory`
/`isLink` derived from `type`, `parent`, `isAbsolute`, `childPath`,
`directoryWith`, `readAsString` on top of `readAsBytes`, `writeAsString` on
top of `writeAsBytes`. Override `type`, `file`, `directory`, `link`, `name`,
`path`, `currentDirectory`, `supportsLink`, `supportsFileLink` on the file
system and `create`, `exists`, `delete`, `rename`, `stat`, `openRead`,
`openWrite`, `list` on the entities. `FileStatModeMixin` returns
`FileStat.modeNotSupported`; `FileExecutableSupport` adds
`setExecutablePermission(bool)`.
