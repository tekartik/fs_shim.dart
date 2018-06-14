library fs_shim.test.utils_glob_test;

import 'package:fs_shim/utils/glob.dart';

import 'test_common.dart';

main() {
  group('glob', () {
    checkMatch(String expression, String name, Matcher matcher) {
      Glob glob = new Glob(expression);
      expect(glob.matches(contextPath(name)), matcher,
          reason: "'$glob' '$name'");
    }

    checkPart(String expression, String name, Matcher matcher) {
      expect(Glob.matchPart(expression, name), matcher,
          reason: "'$expression' '$name'");
    }

    test('equals', () {
      Glob glob1 = new Glob('test');
      Glob glob2 = new Glob('other');
      Glob glob3 = new Glob('test');
      expect(glob1, glob3);
      expect(glob1, isNot(glob2));
      expect(glob1.hashCode, glob3.hashCode);
      expect(glob1.hashCode, isNot(glob2.hashCode));
    });

    test('part', () {
      // null part
      checkPart("", null, isFalse);
      checkPart("*", null, isFalse);
      checkPart("**", null, isFalse);
      checkPart(null, null, isTrue);

      checkPart("test", "test", isTrue);
      checkPart("test", "test_", isFalse);
      checkPart("test", "_test", isFalse);
      checkPart("test", "test_", isFalse);
      checkPart("*", "_test", isTrue);

      checkPart("?", "", isFalse);
      checkPart("?", "a", isTrue);
      checkPart("?", "ab", isFalse);

      checkPart("?est", "test", isTrue);
      checkPart("t?st", "test", isTrue);
      checkPart("tes?", "test", isTrue);

      checkPart("?test", "test", isFalse);
      checkPart("test?", "test", isFalse);
      checkPart("t?est?", "test", isFalse);

      checkPart("*", "", isTrue);
      checkPart("*", "a", isTrue);
      checkPart("*", "ab", isTrue);

      checkPart("*est", "test", isTrue);
      checkPart("t*st", "test", isTrue);
      checkPart("tes*", "test", isTrue);

      checkPart("*test", "test", isTrue);
      checkPart("*est", "test", isTrue);
    });
    test('path', () {
      checkMatch("test", "test", isTrue);
      checkMatch("test", "test_", isFalse);
      checkMatch("test", "_test", isFalse);
      checkMatch("test", "/test", isTrue);
      checkMatch("test", "test/", isTrue);
      checkMatch("/test", "test", isFalse);
      checkMatch("test/", "test", isTrue); // last / ignored
      checkMatch("test", "packages/test", isTrue);
      checkMatch("test", "packages/test_", isFalse);
      checkMatch("test", "test/packages", isTrue);
      checkMatch("packages/test", "packages/test", isTrue);
      checkMatch("packages/test", "a/packages/test/b", isTrue);

      checkMatch("**/test", "test", isTrue);
    });

    test('glob_star', () {
      checkMatch("**", "", isTrue);
      checkMatch("**/a", "a", isTrue);
      checkMatch("**/a", "b/a", isTrue);
      checkMatch("**/a", "c/b/a", isTrue);
      checkMatch("**", "a", isTrue);
      checkMatch("**", "a/b", isTrue);
      checkMatch("a/**", "a", isTrue);
      checkMatch("a/**", "a/b", isTrue);
      checkMatch("a/**", "a/b/c", isTrue);
      checkMatch("a/**/b", "a/b", isTrue);
      checkMatch("a/**/b", "a/c/b", isTrue);
      checkMatch("a/**/b", "a/c/d/b", isTrue);

      checkMatch("**/a", "b", isFalse);
    });

    test('isDir', () {
      expect(new Glob('/').isDir, isTrue);
      expect(new Glob('a/').isDir, isTrue);
      expect(new Glob('a/b/').isDir, isTrue);
      expect(new Glob('a').isDir, isFalse);
      expect(new Glob('a/b').isDir, isFalse);
      expect(new Glob('a/b\\').isDir, isFalse);
    });
  });
}
