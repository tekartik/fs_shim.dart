// ignore_for_file: public_member_api_docs

library;

import 'package:fs_shim/fs.dart' as fs;
import 'package:path/path.dart' as p;

/// OPFS (Origin Private File System) file system.
///
/// Pure type definition, safe to import on any platform.
abstract class FileSystemOpfsWeb extends fs.FileSystem {}

/// Options for `window.showDirectoryPicker()` (File System Access API).
class FileSystemOpfsWebShowDirectoryPickerOptions {
  /// Options for `window.showDirectoryPicker()`.
  const FileSystemOpfsWebShowDirectoryPickerOptions({
    this.id,
    this.mode,
    this.startIn,
  });

  /// [mode] value for read-only access (the default).
  static const modeRead = 'read';

  /// [mode] value for read and write access.
  static const modeReadWrite = 'readwrite';

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

  /// [modeRead] (default) for read-only access or [modeReadWrite] for read
  /// and write access to the directory.
  final String? mode;

  /// A JS `FileSystemHandle` or a well known directory ([startInDesktop],
  /// [startInDocuments], [startInDownloads], [startInMusic],
  /// [startInPictures] or [startInVideos]) to open the dialog in.
  final Object? startIn;
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
