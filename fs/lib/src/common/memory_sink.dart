// ignore_for_file: public_member_api_docs

library;

import 'package:fs_shim/src/common/import.dart';

/// Memory sink.
class MemorySink implements FileStreamSink {
  List<int> content = [];

  /// Memory sink.
  MemorySink();

  final _completer = Completer<void>.sync();

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
  void addError(errorEvent, [StackTrace? stackTrace]) {
    _completer.completeError(errorEvent, stackTrace);
  }

  @override
  Future get done => _done;

  @override
  Future addStream(Stream<List<int>> stream) {
    return stream.listen((data) {
      add(data);
    }).asFuture();
  }

  @override
  Future<void> flush() async {
    // No-op in memory
  }
}
