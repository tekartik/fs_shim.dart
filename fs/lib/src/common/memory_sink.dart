// ignore_for_file: public_member_api_docs

library;

import 'package:fs_shim/src/common/import.dart';
import 'package:meta/meta.dart';

/// Memory sink.
///
/// The content is kept in memory, a subclass writes it in [onClose]; [done]
/// completes once it is written (as io), with its error if it failed.
class MemorySink implements FileStreamSink {
  /// Memory sink.
  MemorySink() {
    // An error is reported by close() too, never as unhandled.
    _doneCompleter.future.ignore();
  }
  List<int> content = [];

  /// Completed on close, or with the error of [addError].
  final _completer = Completer<void>.sync();

  final _doneCompleter = Completer<void>();

  @override
  void add(List<int> data) {
    content.addAll(data);
  }

  /// Write the content, called once by [close].
  @protected
  Future<void> onClose() async {}

  Future<void>? _closing;

  @override
  Future close() => _closing ??= _close();

  Future<void> _close() async {
    if (!_completer.isCompleted) {
      _completer.complete();
    }
    try {
      await _completer.future;
      await onClose();
      _doneCompleter.complete();
    } catch (e, st) {
      _doneCompleter.completeError(e, st);
      rethrow;
    }
  }

  @override
  void addError(errorEvent, [StackTrace? stackTrace]) {
    _completer.completeError(errorEvent, stackTrace);
  }

  @override
  Future get done => _doneCompleter.future;

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
