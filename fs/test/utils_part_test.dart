import 'test_common.dart';

void main() {
  // ignore_for_file: deprecated_member_use_from_same_package
  test('splitParts', () async {
    expect(splitParts('/'), ['/']);
    expect(splitParts('a/b'), ['a', 'b']);
    expect(splitParts('/a'), ['/', 'a']);
    expect(splitParts('\\'), ['\\']);
    expect(splitParts('\\a'), ['\\', 'a']);
  });
}
