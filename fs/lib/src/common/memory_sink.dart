library fs_shim.src.memory_sink;

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

  @override
  void addError(errorEvent, [StackTrace stackTrace]) {
    _completer.completeError(errorEvent, stackTrace);
  }

  @override
  Future get done => _done;

  @override
  Future addStream(Stream<List<int>> stream) {
    return stream.listen((List<int> data) {
      add(data);
    }).asFuture();
  }
}
