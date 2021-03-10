library fs_shim.utils.path;

import 'package:path/path.dart';

/// deprecated See [toPosixPath]
@deprecated
String posixPath(String anyPath) => toPosixPath(anyPath);

/// To posix path.
///
/// \a\b => /a/b
/// /a\b => /a/b
String toPosixPath(String anyPath) => toContextPath(posix, anyPath);

/// To url path (same result than posix)
///
/// \a\b => /a/b
String toUrlPath(String anyPath) => toContextPath(url, anyPath);

/// To windows path (same result than posix)
///
/// /a/b => \a\b
/// \a/b => \a\b
String toWindowsPath(String anyPath) => toContextPath(windows, anyPath);

/// Is part separator (posix/windows/url...
bool isPathPartSeparator(String part) =>
    part == windows.separator || part == url.separator;

/// Split the parts in a given context
///
/// Handle both / and \\ separator
List<String> contextPathSplit(Context context, String path) {
  if (path.isEmpty) {
    throw ArgumentError.value(
        path, 'path', 'contextPathSplit path should not be empty');
  }

  /// We split in the windows context
  var parts = windows.split(path);
  var rootPart = parts[0];
  if (isPathPartSeparator(rootPart) && context.separator != rootPart) {
    parts[0] = context.separator;
  }
  return parts;
}

/// Convert any path in the context mode, dealing with separators.
String toContextPath(Context context, String anyPath) {
  final parts = contextPathSplit(context, anyPath);
  return context.joinAll(parts);
}

/// Deprecated see [toContextPath]
@Deprecated('Sing 2021-02-15')
String contextPath(String anyPath) => toContextPath(context, anyPath);

/// Check if on windows io
@Deprecated('Since 2021-02-15 only reliable for windows io')
bool get contextIsWindows => context.style == windows.style;
