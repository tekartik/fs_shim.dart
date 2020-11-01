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
