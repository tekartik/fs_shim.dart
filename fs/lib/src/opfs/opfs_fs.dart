// ignore_for_file: public_member_api_docs

library;

import 'package:fs_shim/fs.dart' as fs;
import 'package:path/path.dart' as p;

import 'fs_opfs.dart';

/// OPFS (Origin Private File System) file system.
///
/// Pure type definition, safe to import on any platform.
abstract class FileSystemOpfsWeb extends fs.FileSystem {
  /// File system rooted at an existing JS `FileSystemDirectoryHandle`.
  ///
  /// [rootDirectoryHandle] is typically obtained from [showDirectoryPicker]
  /// (Chromium-only) or by wrapping a handle persisted in IndexedDB in a
  /// [FileSystemOpfsWebDirectoryHandle].
  ///
  /// ```dart
  /// final handle = await FileSystemOpfsWeb.showDirectoryPicker();
  /// final fs = FileSystemOpfsWeb.withRootHandle(handle);
  /// ```
  ///
  /// Write operations require the handle to have been granted `readwrite`
  /// permission. Handles do not persist across page reloads unless saved by
  /// the application (e.g. in IndexedDB) and permission requested again.
  ///
  /// Only available on the web. Links and random access are not supported.
  factory FileSystemOpfsWeb.withRootHandle(
    FileSystemOpfsWebDirectoryHandle rootDirectoryHandle,
  ) => fileSystemOpfsWebWithRootHandleImpl(rootDirectoryHandle);

  /// File system whose root "directory" contains exactly [fileHandles], each
  /// at `/<name>` (`name` being the JS handle name, deduplicated as
  /// `name (1)`, `name (2)`, ... on collision).
  ///
  /// [fileHandles] are typically obtained from [showOpenFilePicker] or
  /// [showSaveFilePicker] (Chromium-only) or by wrapping JS
  /// `FileSystemFileHandle`s in [FileSystemOpfsWebFileHandle]s.
  ///
  /// ```dart
  /// final handles = await FileSystemOpfsWeb.showOpenFilePicker(
  ///     FileSystemOpfsWebShowOpenFilePickerOptions(multiple: true));
  /// final fs = FileSystemOpfsWeb.withFileHandles(handles);
  /// await for (final file in fs.directory('/').list()) {
  ///   print(await fs.file(file.path).readAsString());
  /// }
  /// ```
  ///
  /// File handles give no access to their parent directory, so the structure
  /// is fixed: the files can be read, written (permission permitting) and
  /// copied to each other, but not created, deleted or renamed, and no
  /// directory can be created. Handles from [showSaveFilePicker] are writable;
  /// [showOpenFilePicker] handles are read-only unless granted `readwrite`
  /// permission (see [requestWritePermission]).
  ///
  /// Only available on the web. Links and random access are not supported.
  factory FileSystemOpfsWeb.withFileHandles(
    List<FileSystemOpfsWebFileHandle> fileHandles,
  ) => fileSystemOpfsWebWithFileHandlesImpl(fileHandles);

  /// Prompts the user to select a directory using
  /// `window.showDirectoryPicker()` (File System Access API) and returns the
  /// resulting [FileSystemOpfsWebDirectoryHandle], suitable for
  /// [withRootHandle].
  ///
  /// See [FileSystemOpfsWebShowDirectoryPickerOptions] for the available
  /// [options] (`id`, `mode`, `startIn`).
  ///
  /// Chromium-only, must be called from a user gesture. Throws if the user
  /// cancels the picker or if the browser does not support it.
  ///
  /// Only available on the web.
  static Future<FileSystemOpfsWebDirectoryHandle> showDirectoryPicker([
    FileSystemOpfsWebShowDirectoryPickerOptions? options,
  ]) => fileSystemOpfsWebShowDirectoryPickerImpl(options);

  /// Prompts the user to select one or more files using
  /// `window.showOpenFilePicker()` (File System Access API) and returns the
  /// resulting [FileSystemOpfsWebFileHandle]s, suitable for [withFileHandles].
  ///
  /// See [FileSystemOpfsWebShowOpenFilePickerOptions] for the available
  /// [options] (`id`, `startIn`, `multiple`, `excludeAcceptAllOption`,
  /// `types`).
  ///
  /// The returned handles are read-only, writing requires requesting the
  /// `readwrite` permission (see [requestWritePermission]).
  ///
  /// Chromium-only, must be called from a user gesture. Throws if the user
  /// cancels the picker or if the browser does not support it.
  ///
  /// Only available on the web.
  static Future<List<FileSystemOpfsWebFileHandle>> showOpenFilePicker([
    FileSystemOpfsWebShowOpenFilePickerOptions? options,
  ]) => fileSystemOpfsWebShowOpenFilePickerImpl(options);

  /// Prompts the user to select a file to save to using
  /// `window.showSaveFilePicker()` (File System Access API) and returns the
  /// resulting [FileSystemOpfsWebFileHandle], suitable for [withFileHandles].
  ///
  /// The file is created empty if it does not exist yet, and the returned
  /// handle is granted `readwrite` permission.
  ///
  /// See [FileSystemOpfsWebShowSaveFilePickerOptions] for the available
  /// [options] (`id`, `startIn`, `suggestedName`, `excludeAcceptAllOption`,
  /// `types`).
  ///
  /// Chromium-only, must be called from a user gesture. Throws if the user
  /// cancels the picker or if the browser does not support it.
  ///
  /// Only available on the web.
  static Future<FileSystemOpfsWebFileHandle> showSaveFilePicker([
    FileSystemOpfsWebShowSaveFilePickerOptions? options,
  ]) => fileSystemOpfsWebShowSaveFilePickerImpl(options);

  /// Requests the `readwrite` permission on [handle] (a
  /// [FileSystemOpfsWebFileHandle] or a [FileSystemOpfsWebDirectoryHandle])
  /// and returns true if granted.
  ///
  /// Needed before writing to a file handle obtained from
  /// [showOpenFilePicker]. May prompt the user, in which case a user gesture
  /// is required.
  ///
  /// Chromium-only. Only available on the web.
  static Future<bool> requestWritePermission(
    FileSystemOpfsWebFileSystemEntityHandle handle,
  ) => fileSystemOpfsWebRequestWritePermissionImpl(handle);

  /// Returns the OPFS root directory handle using `navigator.storage.getDirectory()`.
  ///
  /// Only available on the web.
  static Future<FileSystemOpfsWebDirectoryHandle> storageGetDirectory() =>
      fileSystemOpfsWebStorageGetDirectoryImpl();
}

/// Common options for the File System Access API pickers
/// (`window.showDirectoryPicker()`, `window.showOpenFilePicker()` and
/// `window.showSaveFilePicker()`).
abstract class FileSystemOpfsWebPickerOptions {
  /// Common picker options.
  const FileSystemOpfsWebPickerOptions({this.id, this.startIn});

  /// [startIn] well known directory: the user's desktop.
  static const startInDesktop = 'desktop';

  /// [startIn] well known directory: the user's documents.
  static const startInDocuments = 'documents';

  /// [startIn] well known directory: the user's downloads.
  static const startInDownloads = 'downloads';

  /// [startIn] well known directory: the user's music.
  static const startInMusic = 'music';

  /// [startIn] well known directory: the user's pictures.
  static const startInPictures = 'pictures';

  /// [startIn] well known directory: the user's videos.
  static const startInVideos = 'videos';

  /// By specifying an ID, the browser can remember different directories for
  /// different IDs. If the same ID is used for another picker, the picker
  /// opens in the same directory.
  final String? id;

  /// A JS `FileSystemHandle` or a well known directory ([startInDesktop],
  /// [startInDocuments], [startInDownloads], [startInMusic],
  /// [startInPictures] or [startInVideos]) to open the dialog in.
  final Object? startIn;
}

/// Options for `window.showDirectoryPicker()` (File System Access API).
class FileSystemOpfsWebShowDirectoryPickerOptions
    extends FileSystemOpfsWebPickerOptions {
  /// Options for `window.showDirectoryPicker()`.
  const FileSystemOpfsWebShowDirectoryPickerOptions({
    super.id,
    this.mode,
    super.startIn,
  });

  /// [mode] value for read-only access (the default).
  static const modeRead = 'read';

  /// [mode] value for read and write access.
  static const modeReadWrite = 'readwrite';

  /// [modeRead] (default) for read-only access or [modeReadWrite] for read
  /// and write access to the directory.
  final String? mode;
}

/// A file type accepted by the file pickers (an entry of the `types` option of
/// `window.showOpenFilePicker()` and `window.showSaveFilePicker()`).
class FileSystemOpfsWebFilePickerAcceptType {
  /// A file type accepted by the file pickers.
  const FileSystemOpfsWebFilePickerAcceptType({
    this.description,
    required this.accept,
  });

  /// Optional description of the category of files types allowed.
  final String? description;

  /// MIME type to list of extensions, e.g. `{'text/plain': ['.txt']}`.
  final Map<String, List<String>> accept;
}

/// Options for `window.showOpenFilePicker()` (File System Access API).
class FileSystemOpfsWebShowOpenFilePickerOptions
    extends FileSystemOpfsWebPickerOptions {
  /// Options for `window.showOpenFilePicker()`.
  const FileSystemOpfsWebShowOpenFilePickerOptions({
    super.id,
    super.startIn,
    this.multiple,
    this.excludeAcceptAllOption,
    this.types,
  });

  /// Whether the user can select multiple files (defaults to false).
  final bool? multiple;

  /// Whether the picker should hide the option to not apply any of the
  /// [types] filters (defaults to false).
  final bool? excludeAcceptAllOption;

  /// The file types the picker allows to select.
  final List<FileSystemOpfsWebFilePickerAcceptType>? types;
}

/// Options for `window.showSaveFilePicker()` (File System Access API).
class FileSystemOpfsWebShowSaveFilePickerOptions
    extends FileSystemOpfsWebPickerOptions {
  /// Options for `window.showSaveFilePicker()`.
  const FileSystemOpfsWebShowSaveFilePickerOptions({
    super.id,
    super.startIn,
    this.suggestedName,
    this.excludeAcceptAllOption,
    this.types,
  });

  /// The suggested file name.
  final String? suggestedName;

  /// Whether the picker should hide the option to not apply any of the
  /// [types] filters (defaults to false).
  final bool? excludeAcceptAllOption;

  /// The file types the picker allows to save as.
  final List<FileSystemOpfsWebFilePickerAcceptType>? types;
}

/// Posix path context used by the OPFS file system (even on Windows), with the
/// root being the OPFS root directory.
final p.Context opfsPathContext = p.Context(style: p.Style.posix, current: '/');

/// Make a path absolute (rooted at `/`).
String opfsMakePathAbsolute(String path) {
  if (opfsPathContext.isAbsolute(path)) {
    return opfsPathContext.normalize(path);
  }
  return opfsPathContext.normalize(opfsPathContext.join('/', path));
}

/// Split a path into its name segments, without the leading separator.
///
/// e.g `/a/b` and `a/b` both return `['a', 'b']`, `/` returns `[]`.
List<String> opfsPathSegments(String path) {
  final normalized = opfsMakePathAbsolute(path);
  final segments = opfsPathContext.split(normalized);
  return segments
      .where(
        (segment) => segment != opfsPathContext.separator && segment != '.',
      )
      .toList();
}

/// JS `FileSystemDirectoryHandle`, only available on the web (where it is
/// simply a `JSObject`).
abstract class FileSystemOpfsWebDirectoryHandle
    implements FileSystemOpfsWebFileSystemEntityHandle {}

/// JS `FileSystemFileHandle`, only available on the web (where it is
/// simply a `JSObject`).
abstract class FileSystemOpfsWebFileHandle
    implements FileSystemOpfsWebFileSystemEntityHandle {}

/// Wraps a JS `FileSystemHandle`, either a file
/// ([FileSystemOpfsWebFileHandle]) or a directory
/// ([FileSystemOpfsWebDirectoryHandle]) handle.
abstract class FileSystemOpfsWebFileSystemEntityHandle {}
