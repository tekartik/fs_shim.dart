// ignore_for_file: close_sinks

library;

import 'dart:typed_data';

import 'package:fs_shim/src/common/bytes_utils.dart';
import 'package:fs_shim/src/common/memory_sink.dart';

import 'test_common.dart';

class _OwnedMemorySink extends MemorySink {
  void addOwned(Uint8List bytes) => addOwnedBytes(bytes);
}

void main() {
  group('memory_sink', () {
    test('add copies, content merges', () {
      var sink = MemorySink();
      expect(sink.contentLength, 0);
      expect(sink.content, isEmpty);
      var buffer = Uint8List.fromList([1, 2, 3]);
      sink.add(buffer);
      // The caller reuses its buffer.
      buffer[0] = 9;
      sink.add([4, 5]);
      sink.add(<int>[]);
      expect(sink.contentLength, 5);
      expect(sink.content, [1, 2, 3, 4, 5]);
      expect(sink.content, isA<Uint8List>());
      // Merged once.
      expect(identical(sink.content, sink.content), isTrue);
      sink.content = [7];
      expect(sink.content, [7]);
      expect(sink.contentLength, 1);
    });

    test('skipContent', () {
      var sink = MemorySink()
        ..add([1, 2])
        ..add([3, 4, 5])
        ..add([6]);
      sink.skipContent(0);
      expect(sink.content, [1, 2, 3, 4, 5, 6]);

      sink = MemorySink()
        ..add([1, 2])
        ..add([3, 4, 5])
        ..add([6]);
      // Across a chunk boundary, the rest kept.
      sink.skipContent(3);
      expect(sink.contentLength, 3);
      sink.add([7]);
      expect(sink.content, [4, 5, 6, 7]);
      // Exactly a chunk.
      sink.skipContent(4);
      expect(sink.contentLength, 0);
      expect(sink.content, isEmpty);

      sink = MemorySink()
        ..add([1, 2])
        ..add([3]);
      sink.skipContent(2);
      expect(sink.content, [3]);
      sink.skipContent(10);
      expect(sink.contentLength, 0);
    });

    test('takeContent', () {
      var sink = MemorySink()
        ..add([1])
        ..add([2, 3]);
      expect(sink.takeContent(), [1, 2, 3]);
      expect(sink.contentLength, 0);
      expect(sink.takeContent(), isEmpty);
    });

    test('addOwnedBytes', () {
      var sink = _OwnedMemorySink();
      var bytes = Uint8List.fromList([1, 2]);
      sink.addOwned(bytes);
      sink.addOwned(Uint8List(0));
      expect(sink.contentLength, 2);
      // Not copied.
      expect(identical(sink.content, bytes), isTrue);
    });
  });

  test('bytesListToBytes', () {
    expect(bytesListToBytes([]), isEmpty);
    var bytes = bytesListToBytes([
      Uint8List.fromList([1, 2]),
      [3],
      <int>[],
      Uint8List.fromList([4]),
    ]);
    expect(bytes, [1, 2, 3, 4]);
    expect(bytes, isA<Uint8List>());
    // Always a new buffer.
    var single = Uint8List.fromList([1]);
    expect(identical(bytesListToBytes([single]), single), isFalse);
  });
}
