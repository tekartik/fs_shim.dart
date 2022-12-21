import 'dart:typed_data';

/// Concert a list to byte array
Uint8List asUint8List(List<int> bytes) {
  if (bytes is Uint8List) {
    return bytes;
  }
  return Uint8List.fromList(bytes);
}

/// Convert a list of list of bytes to a buffer
Uint8List bytesListToBytes(List<List<int>> bytesList) {
  return asUint8List(bytesList.expand((element) => element).toList());
}

/// Stream list of bytes to a buffer
Future<Uint8List> streamToBytes(Stream<List<int>> stream) async {
  return bytesListToBytes(await stream.toList());
}

/// Split a list in sub list with a maximum size.
///
/// Never returns list. if list is null, returns an empty list.
/// If [chunkSize] is null or 0, returns all in one list;
List<Uint8List> uint8ListChunk<T>(Uint8List list, int? chunkSize) {
  var chunks = <Uint8List>[];
  final len = list.length;
  if ((chunkSize ?? 0) == 0) {
    chunkSize = len;
  }
  for (var i = 0; i < len; i += chunkSize) {
    final size = i + chunkSize!;
    chunks.add(list.sublist(i, size > len ? len : size));
  }

  return chunks;
}
