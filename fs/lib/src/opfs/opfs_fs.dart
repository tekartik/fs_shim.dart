// ignore_for_file: public_member_api_docs

library;

import 'package:fs_shim/fs.dart' as fs;
import 'package:path/path.dart' as p;

/// OPFS (Origin Private File System) file system.
///
/// Pure type definition, safe to import on any platform.
abstract class FileSystemOpfsWeb extends fs.FileSystem {}

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
