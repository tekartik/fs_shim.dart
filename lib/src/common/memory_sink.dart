library tekartik_fs_shim.src.memory_sink;

import 'dart:async';
//import 'dart:convert';

class MemorySink implements StreamSink<List<int>> {
  List<int> content = [];

  MemorySink();

  Completer _completer = new Completer.sync();
  Future get _done => _completer.future;
  @override
  void add(List<int> data) {
    content.addAll(data);
  }

  @override
  Future close() async {
    if (!_completer.isCompleted) {
      _completer.complete();
    }
    return done;
  }

  void addError(errorEvent, [StackTrace stackTrace]) {
    _completer.completeError(errorEvent, stackTrace);
  }

  Future get done => _done;

  Future addStream(Stream<List> stream) {
    return stream.listen((List<int> data) {
      add(data);
    }).asFuture();
  }
}
