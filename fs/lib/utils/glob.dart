library;

import 'package:fs_shim/src/common/import.dart';
import 'package:path/path.dart';

//
// Matcher for a single path portion
//
class _PartMatchRunner {
  String? glob;
  late String part;

  int globIndex = 0;
  int partIndex = 0;

  bool inStar = false;

  bool matches() {
    // at the end?
    final partChr = partIndex == part.length ? null : part[partIndex];
    final globChr = globIndex == glob!.length ? null : glob![globIndex];

    bool next() {
      globIndex++;
      partIndex++;
      final ok = matches();
      globIndex--;
      partIndex--;
      return ok;
    }

    if (globChr == partChr) {
      // Same char ok
      // if null we're done
      if (partChr == null) {
        return true;
      }
      return next();
    } else if (globChr == '?') {
      // must match a char
      if (partChr == null) {
        return false;
      }
      // any char
      return next();
    } else if (globChr == '*') {
      // any number char
      // try with zero
      partIndex--;
      var matches = next();
      partIndex++;

      if (!matches && partChr != null) {
        // try with one matching
        matches = next();

        // try with skipping
        if (!matches) {
          globIndex--;
          matches = next();
          globIndex++;
        }
      }
      /*
      bool matches = (partChr != null)_next();
      if (!matches) {
        // try with 0
        globIndex--;
        matches = _next();
        globIndex++;
*/
      /*
        if (!matches) {
          // try with 1
          partIndex--;
          matches = _next();
          partIndex++;
        }
        */

      return matches;
    } else {
      return false;
    }
  }

  @override
  String toString() => "'$glob' $globIndex '$part' $partIndex";
}

class _GlobMatchRunner {
  Glob glob;
  List<String> parts;

  List<String>? get globParts => glob._expressionParts;

  _GlobMatchRunner(this.glob, this.parts);

  int globIndex = 0;
  int partIndex = 0;

  bool _next() {
    globIndex++;
    partIndex++;
    final ok = matchesFromCurrent();
    globIndex--;
    partIndex--;
    return ok;
  }

  bool matchesFromCurrent() {
    // at the end?
    final partEnd = partIndex == parts.length;
    final globEnd = globIndex == globParts!.length;
    if (globEnd) {
      return true;
    }

    final part = partEnd ? null : parts[partIndex];
    final globPart = globParts![globIndex];

    if (Glob.isGlobStar(globPart)) {
      var ok = false;
      // Try 0

      partIndex--;
      ok = _next();
      partIndex++;

      if (!ok && part != null) {
        // try 1
        ok = _next();

        // try skip 1
        if (!ok) {
          globIndex--;
          ok = _next();
          globIndex++;
        }
      }
      return ok;
    } else if (Glob.matchPart(globPart, part)) {
      return _next();
    } else {
      return false;
    }
  }

  bool matches() {
    if (matchesFromCurrent()) {
      return true;
    }

    // Try on below
    if (++partIndex < parts.length) {
      return matches();
    }
    return false;
  }

  @override
  String toString() => "'$glob' $globIndex '$parts' $partIndex";
}

/// Glob matching search.
/// only support / * ** and ?
///
/// Convert everything to url internally
class Glob {
  /// Glob star (**) matches everything and subdirs
  static bool isGlobStar(String globPart) => globPart == '**';

  /// Check single part.
  /// * The ? matches 1 of any character in a single path portion
  /// * The * matches 0 or more of any character in a single path portion
  /// * If a "globstar" is alone in a path portion, then it matches zero or more directories and subdirectories searching for matches.
  static bool matchPart(String? globPart, String? part) {
    if (part == null) {
      return globPart == null;
    }
    final runner =
        _PartMatchRunner()
          ..glob = globPart
          ..part = part;
    return runner.matches();
  }

  /// Global expression.
  String expression;
  List<String>? __expressionParts;

  List<String>? get _expressionParts {
    __expressionParts ??= posix.split(expression);

    return __expressionParts;
  }

  /// Global expression.
  Glob(this.expression) {
    __expressionParts = posix.split(expression);
  }

  /// true if the name matches the pattern
  bool matches(String name) {
    try {
      final runner = _GlobMatchRunner(this, contextPathSplit(posix, name));
      return runner.matches();
    } catch (_) {
      return false;
    }
  }

  /// True if it matches a path defined by parts.
  bool matchesParts(List<String> parts) {
    final runner = _GlobMatchRunner(this, parts);
    return runner.matches();
  }

  @override
  String toString() => '$_expressionParts';

  /// True if the expression matches a dir (ends with '/').
  bool get isDir => expression.endsWith(posix.separator);

  @override
  int get hashCode => expression.hashCode;

  @override
  bool operator ==(Object other) {
    if (other is Glob) {
      return other.expression == expression;
    }
    return false;
  }
}
