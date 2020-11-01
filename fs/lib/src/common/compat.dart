import 'dart:async';
import 'dart:typed_data';

import 'package:fs_shim/src/common/import.dart';

// 2.5 compatibility change
export 'bytes_utils.dart' show asUint8List;

// 2.5 compatibility change
//
// TODO 2019/07/08 This could be removed once the stable API returns Uint8List everywhere
// ignore: public_member_api_docs
Stream<Uint8List> intListStreamToUint8ListStream(Stream stream) {
  if (stream is Stream<Uint8List>) {
    return stream;
  } else if (stream is Stream<List<int>>) {
    return stream.transform(
        StreamTransformer<List<int>, Uint8List>.fromHandlers(
            handleData: (list, sink) {
      sink.add(Uint8List.fromList(list));
    }));
  } else {
    throw ArgumentError('Invalid stream type: ${stream.runtimeType}');
  }
}
