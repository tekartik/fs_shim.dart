// ignore_for_file: public_member_api_docs

library;

import 'package:path/path.dart' as p;

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
