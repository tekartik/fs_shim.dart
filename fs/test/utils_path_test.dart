import 'package:path/path.dart';

import 'test_common.dart';

void main() {
  group('utils_path', () {
    test('split', () {
      try {
        expect(contextPathSplit(windows, ''), ['']);
      } on ArgumentError catch (_) {}
      expect(contextPathSplit(windows, 'a/b'), ['a', 'b']);
      expect(contextPathSplit(windows, 'a'), ['a']);
      expect(contextPathSplit(windows, '/'), ['\\']);
      expect(contextPathSplit(windows, '\\'), ['\\']);
      expect(
          contextPathSplit(windows, '\\a/b\\c/d'), ['\\', 'a', 'b', 'c', 'd']);
      expect(contextPathSplit(url, '/'), ['/']);
      expect(contextPathSplit(url, '\\'), ['/']);
      expect(contextPathSplit(url, '\\a/b\\c/d'), ['/', 'a', 'b', 'c', 'd']);
    });
    test('posixPath', () {
      expect(toPosixPath('/'), '/');

      expect(toPosixPath('a'), 'a');
      expect(toPosixPath('a/'), 'a');
      expect(toPosixPath('a\\'), 'a');
      expect(toPosixPath('\\'), '/');
      expect(toPosixPath('/a'), '/a');
      expect(toPosixPath('\\a'), '/a');
      expect(toPosixPath('a/b'), 'a/b');
      expect(toPosixPath('a\\b'), 'a/b');
      expect(toPosixPath('\\a/b'), '/a/b');
      expect(toPosixPath('/a\\b'), '/a/b');
      expect(toPosixPath('C:\\'), '/C:');
      expect(toPosixPath('C:\\a'), '/C:/a');
    });
    test('urlPath', () {
      // same as toPosixPath...
      expect(toUrlPath('/'), '/');
      expect(toUrlPath('a'), 'a');
      expect(toUrlPath('\\'), '/');
    });
    test('toWindowsPath', () {
      expect(toWindowsPath('/C:/'), 'C:');
      expect(toWindowsPath('/C:/a'), 'C:\\a');
      expect(toWindowsPath('C:\\'), 'C:\\');
      expect(toWindowsPath('C:\\a/b'), 'C:\\a\\b');
      expect(toWindowsPath('/'), '\\');
      expect(toWindowsPath('a'), 'a');
      expect(toWindowsPath('a/'), 'a');
      expect(toWindowsPath('a\\'), 'a');
      expect(toWindowsPath('\\'), '\\');
      expect(toWindowsPath('/a'), '\\a');
      expect(toWindowsPath('\\a'), '\\a');
      expect(toWindowsPath('a/b'), 'a\\b');
      expect(toWindowsPath('a\\b'), 'a\\b');
      expect(toWindowsPath('\\a/b'), '\\a\\b');
      expect(toWindowsPath('/a\\b'), '\\a\\b');
    });
    // Kept for quick experiment
    group('raw_exp', () {
      test('windows', () {
        // Raw experiment
        expect(windows.split('/a'), ['/', 'a']);
        expect(windows.split('\\a'), ['\\', 'a']);
        expect(windows.split('C:\\a'), ['C:\\', 'a']);
        expect(windows.split('\\a/b'), ['\\', 'a', 'b']); // best implementation
        expect(windows.basename('a/b'), 'b');
        expect(windows.basename('a\\b'), 'b');
      });
      test('posix', () {
        expect(posix.split('/a'), ['/', 'a']);
        expect(posix.split('C:\\a'), ['C:\\a']);
        expect(posix.split('\\a'), ['\\a']); // !!! args
        expect(posix.split('\\a/b'), ['\\a', 'b']); // !!! args

        expect(posix.basename('a/b'), 'b');
        expect(posix.basename('a\\b'),
            'a\\b'); // !!!! posix does not convert windows style correctly
      });

      test('convert', () {
        final path = 'c:\\windows\\system';
        expect(windows.joinAll(windows.split(path)), path);
        final posixPath = posix.joinAll(windows.split(path));
        expect(windows.joinAll(posix.split(posixPath)), path);
        expect(windows.joinAll(windows.split(posixPath)),
            path); // !event this works
      });
    });
  });
}
