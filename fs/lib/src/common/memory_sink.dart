// ignore_for_file: public_member_api_docs

library;

import 'dart:typed_data';

import 'package:fs_shim/src/common/bytes_utils.dart';
import 'package:fs_shim/src/common/import.dart';
import 'package:meta/meta.dart';

/// Memory sink.
///
/// The content is kept in memory, a subclass writes it in [onClose]; [done]
/// completes once it is written (as io), with its error if it failed.
///
/// The bytes are kept as the `Uint8List` chunks added (copied on [add]), never
/// in a `List<int>`: copying byte by byte was the cost of every write (about
/// 25 MiB/s on the web) and a `List<int>` is a JS array on dart2js, limited to
/// 2^27 elements (no file of 128 MiB or more could be written).
class MemorySink implements FileStreamSink {
  /// Memory sink.
  MemorySink() {
    // An error is reported by close() too, never as unhandled.
    _doneCompleter.future.ignore();
  }

  final _chunks = <Uint8List>[];
  var _length = 0;

  /// Number of bytes added and not taken.
  int get contentLength => _length;

  /// The bytes added and not taken, kept by the sink (do not modify).
  ///
  /// The chunks are merged into one buffer, returned again until the next
  /// [add].
  Uint8List get content {
    if (_chunks.isEmpty) {
      return Uint8List(0);
    }
    if (_chunks.length > 1) {
      var merged = bytesListToBytes(_chunks);
      _chunks
        ..clear()
        ..add(merged);
    }
    return _chunks.first;
  }

  /// Replaces the bytes kept by a copy of [bytes].
  set content(List<int> bytes) {
    _clearContent();
    add(bytes);
  }

  void _clearContent() {
    _chunks.clear();
    _length = 0;
  }

  /// The bytes added and not taken, removed from the sink.
  Uint8List takeContent() {
    var bytes = content;
    _clearContent();
    return bytes;
  }

  /// Removes the first [count] bytes kept (written by a subclass).
  void skipContent(int count) {
    if (count <= 0) {
      return;
    }
    if (count >= _length) {
      _clearContent();
      return;
    }
    var remaining = count;
    var drop = 0;
    while (remaining >= _chunks[drop].length) {
      remaining -= _chunks[drop].length;
      drop++;
    }
    _chunks.removeRange(0, drop);
    if (remaining > 0) {
      // A copy: a view would keep the whole buffer alive.
      _chunks[0] = Uint8List.fromList(
        Uint8List.sublistView(_chunks[0], remaining),
      );
    }
    _length -= count;
  }

  /// Adds [bytes] without copying it, the sink owns it (a buffer made by the
  /// caller, never modified after).
  @protected
  void addOwnedBytes(Uint8List bytes) {
    if (bytes.isEmpty) {
      return;
    }
    _chunks.add(bytes);
    _length += bytes.length;
  }

  /// Completed on close, or with the error of [addError].
  final _completer = Completer<void>.sync();

  final _doneCompleter = Completer<void>();

  /// Adds a copy of [data] (as io, the caller may reuse its buffer).
  @override
  void add(List<int> data) {
    if (data.isEmpty) {
      return;
    }
    addOwnedBytes(Uint8List.fromList(data));
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
