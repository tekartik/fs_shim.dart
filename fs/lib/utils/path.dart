library fs_shim.utils.path;

import 'package:path/path.dart';

/// deprecated See [toPosixPath]
@Deprecated('Use toPosixPath()')
String posixPath(String anyPath) => toPosixPath(anyPath);

/// To posix path.
///
/// \a\b => /a/b
/// /a\b => /a/b
/// C:\ => /C:/
String toPosixPath(String anyPath) {
  var context = posix;
  var parts = contextPathSplit(context, anyPath);
  // Handle C:\
  if (parts.isNotEmpty) {
    var rootPart = parts[0];

    if (rootPart.endsWith(':')) {
      parts = ['/', ...parts];
    } else if (rootPart.endsWith(':\\')) {
      parts = [
        '/',
        rootPart.substring(0, rootPart.length - 1),
        ...parts.sublist(1)
      ];
    }
  }
  return context.joinAll(parts);
}

/// To url path (same result than posix)
///
/// \a\b => /a/b
String toUrlPath(String anyPath) => toPosixPath(anyPath);

/// To windows path (same result than posix)
///
/// /a/b => \a\b
/// \a/b => \a\b
/// /c:/ => C:\
String toWindowsPath(String anyPath) {
  var context = windows;
  var parts = contextPathSplit(context, anyPath);
  // Handle C:\xxx
  if (parts.length > 1 && parts[1].endsWith(':')) {
    parts = parts.sublist(1);
  }
  return context.joinAll(parts);
}

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
  // Handle /C:/ parsing
  if (parts.length > 1 && parts[1].endsWith(':')) {
    parts = parts.sublist(1);
  }

  return parts;
}

/// Convert any path in the context mode, dealing with separators.
String toContextPath(Context context, String anyPath) {
  if (context.style == windows.style) {
    return toWindowsPath(anyPath);
  } else {
    return toPosixPath(anyPath);
  }
}

/// Deprecated see [toContextPath]
@Deprecated('Sing 2021-02-15')
String contextPath(String anyPath) => toNativePath(anyPath);

/// Convert any path to the current context mode (typically io), dealing with separators.
///
/// typically called with a posix style
///
/// on windows: dir/sub will give dir\sub
String toNativePath(String anyPath) => toContextPath(context, anyPath);

/// Check if on windows io
@Deprecated('Since 2021-02-15 only reliable for windows io')
bool get contextIsWindows => context.style == windows.style;
