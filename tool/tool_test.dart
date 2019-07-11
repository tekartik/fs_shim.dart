import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';

Version parsePlatformVersion(String text) {
  return Version.parse(text.split(' ').first);
}

void main() {
  test('parsePlatformVersion', () {
    expect(
        parsePlatformVersion(
            '2.3.0-dev.0.3 (Tue Apr 23 12:02:59 2019 -0700) on "linux_x64"'),
        Version(2, 3, 0, pre: 'dev.0.3'));

    var newVersion = parsePlatformVersion(
        '2.5.0-dev.1.0 (Tue Jul 9 15:27:01 2019 +0200) on "linux_x64"');
    expect(
        newVersion,
        Version(2, 5, 0, pre:'dev.1.0'));
    expect(newVersion, greaterThan(Version(2, 5, 0, pre: 'dev')));
  });
}
