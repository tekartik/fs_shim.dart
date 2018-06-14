library fs_shim.utils.glob;

import 'package:path/path.dart';

import '../src/common/import.dart';

//
// Matcher for a single path portion
//
class _PartMatchRunner {
  String glob;
  String part;

  int globIndex = 0;
  int partIndex = 0;

  bool inStar = false;
  bool matches() {
    // at the end?
    String partChr = partIndex == part.length ? null : part[partIndex];
    String globChr = globIndex == glob.length ? null : glob[globIndex];

    bool _next() {
      globIndex++;
      partIndex++;
      bool ok = matches();
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
      return _next();
    } else if (globChr == '?') {
      // must match a char
      if (partChr == null) {
        return false;
      }
      // any char
      return _next();
    } else if (globChr == '*') {
      // any number char
      // try with zero
      partIndex--;
      bool matches = _next();
      partIndex++;

      if (!matches && partChr != null) {
        // try with one matching
        matches = _next();

        // try with skipping
        if (!matches) {
          globIndex--;
          matches = _next();
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
  List<String> get globParts => glob._expressionParts;
  _GlobMatchRunner(this.glob, this.parts);

  int globIndex = 0;
  int partIndex = 0;

  bool _next() {
    globIndex++;
    partIndex++;
    bool ok = matchesFromCurrent();
    globIndex--;
    partIndex--;
    return ok;
  }

  bool matchesFromCurrent() {
    // at the end?
    bool partEnd = partIndex == parts.length;
    bool globEnd = globIndex == globParts.length;
    if (globEnd) {
      return true;
    }

    String part = partEnd ? null : parts[partIndex];
    String globPart = globParts[globIndex];

    if (Glob.isGlobStar(globPart)) {
      bool ok = false;
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

// only support / * ** and ?
class Glob {
  static bool isGlobStar(String globPart) => globPart == '**';

  // The ? matches 1 of any character in a single path portion
  // The * matches 0 or more of any character in a single path portion
  // ** If a "globstar" is alone in a path portion, then it matches zero or more directories and subdirectories searching for matches.
  static bool matchPart(String globPart, String part) {
    if (part == null) {
      return globPart == null;
    }
    _PartMatchRunner runner = new _PartMatchRunner()
      ..glob = globPart
      ..part = part;
    return runner.matches();
  }

  String expression;
  List<String> __expressionParts;

  List<String> get _expressionParts {
    if (__expressionParts == null) {
      __expressionParts = split(expression);
    }
    return __expressionParts;
  }

  Glob(this.expression) {
    __expressionParts = posix.split(expression);
  }

  /// true if the name matches the pattern
  bool matches(String name) {
    _GlobMatchRunner runner = new _GlobMatchRunner(this, splitParts(name));
    return runner.matches();
  }

  bool matchesParts(List<String> parts) {
    _GlobMatchRunner runner = new _GlobMatchRunner(this, parts);
    return runner.matches();
  }

  @override
  String toString() => '$_expressionParts';

  bool get isDir => expression.endsWith(posix.separator);

  @override
  int get hashCode => expression.hashCode;

  @override
  bool operator ==(o) {
    if (o is Glob) {
      return o.expression == expression;
    }
    return false;
  }
}
