import 'test_common.dart';

void main() {
  test('splitParts', () async {
    expect(splitParts('a/b'), ['a', 'b']);
    if (!contextIsWindows) {
      expect(splitParts('/'), ['/']);
      //expect(splitParts('\\'), ['/']);
    }
  });
}
