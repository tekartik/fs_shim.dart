import 'dart:io' as io;
import 'dart:typed_data';

import 'package:fs_shim/src/common/fs_random_access_file_none.dart';
import 'package:fs_shim/src/random_access_file.dart';

import 'io_fs.dart';

/// Io RandomAccessFile implementation.
class IoRandomAccessFile with DefaultRandomAccessFileMixin {
  /// The io file
  final io.RandomAccessFile ioRandomAccessFile;

  IoRandomAccessFile _me(_) => this;
  static IoRandomAccessFile _wrap(io.RandomAccessFile ioRandomAccessFile) =>
      IoRandomAccessFile(ioRandomAccessFile);

  /// Io RandomAccessFile implementation.
  IoRandomAccessFile(this.ioRandomAccessFile);

  @override
  Future<void> close() => ioWrapCall(() => ioRandomAccessFile.close());

  @override
  Future<RandomAccessFile> flush() =>
      ioWrapCall(() => ioRandomAccessFile.flush()).then(_me);

  @override
  Future<int> length() => ioWrapCall(() => ioRandomAccessFile.length());

  @override
  String get path => ioWrapCallSync(() => ioRandomAccessFile.path);

  @override
  Future<int> position() => ioWrapCall(() => ioRandomAccessFile.position());

  @override
  Future<Uint8List> read(int count) =>
      ioWrapCall(() => ioRandomAccessFile.read(count));

  @override
  Future<int> readByte() => ioWrapCall(() => ioRandomAccessFile.readByte());

  @override
  Future<int> readInto(List<int> buffer, [int start = 0, int? end]) =>
      ioWrapCall(() => ioRandomAccessFile.readInto(buffer, start, end));

  @override
  Future<RandomAccessFile> setPosition(int position) =>
      ioWrapCall(() => ioRandomAccessFile.setPosition(position)).then(_wrap);

  @override
  Future<RandomAccessFile> truncate(int length) =>
      ioWrapCall(() => ioRandomAccessFile.truncate(length)).then(_wrap);

  @override
  Future<RandomAccessFile> writeByte(int value) =>
      ioWrapCall(() => ioRandomAccessFile.writeByte(value)).then(_wrap);

  @override
  Future<RandomAccessFile> writeFrom(List<int> buffer,
          [int start = 0, int? end]) =>
      ioWrapCall(() => ioRandomAccessFile.writeFrom(buffer, start, end))
          .then(_wrap);

  @override
  Future<RandomAccessFile> writeString(String string,
          {Encoding encoding = utf8}) =>
      ioWrapCall(
              () => ioRandomAccessFile.writeString(string, encoding: encoding))
          .then(_wrap);
}
