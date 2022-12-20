import 'dart:convert';
import 'dart:typed_data';

/// Random access to the data in a file.
///
/// `RandomAccessFile` objects are obtained by calling the
/// `open` method on a [File] object.
///
/// A `RandomAccessFile` has both asynchronous and synchronous
/// methods. The asynchronous methods all return a [Future]
/// whereas the synchronous methods will return the result directly,
/// and block the current isolate until the result is ready.
///
/// At most one asynchronous method can be pending on a given `RandomAccessFile`
/// instance at the time. If another asynchronous method is called when one is
/// already in progress, a [FileSystemException] is thrown.
///
/// If an asynchronous method is pending, it is also not possible to call any
/// synchronous methods. This will also throw a [FileSystemException].
abstract class RandomAccessFile {
  /// Closes the file.
  ///
  /// Returns a [Future] that completes when it has been closed.
  Future<void> close();

  /// Reads a byte from the file.
  ///
  /// Returns a `Future<int>` that completes with the byte,
  /// or with -1 if end-of-file has been reached.
  Future<int> readByte();

  /// Reads up to [count] bytes from a file.
  Future<Uint8List> read(int count);

  /// Reads bytes into an existing [buffer].
  ///
  /// Reads bytes and writes then into the range of [buffer]
  /// from [start] to [end].
  /// The [start] must be non-negative and no greater than [buffer].length.
  /// If [end] is omitted, it defaults to [buffer].length.
  /// Otherwise [end] must be no less than [start]
  /// and no greater than [buffer].length.
  ///
  /// Returns the number of bytes read. This maybe be less than `end - start`
  /// if the file doesn't have that many bytes to read.
  Future<int> readInto(List<int> buffer, [int start = 0, int? end]);

  /// Writes a single byte to the file.
  ///
  /// Returns a `Future<RandomAccessFile>` that completes with this
  /// random access file when the write completes.
  Future<RandomAccessFile> writeByte(int value);

  /// Writes from a [buffer] to the file.
  ///
  /// Will read the buffer from index [start] to index [end].
  /// The [start] must be non-negative and no greater than [buffer].length.
  /// If [end] is omitted, it defaults to [buffer].length.
  /// Otherwise [end] must be no less than [start]
  /// and no greater than [buffer].length.
  ///
  /// Returns a `Future<RandomAccessFile>` that completes with this
  /// [RandomAccessFile] when the write completes.
  Future<RandomAccessFile> writeFrom(List<int> buffer,
      [int start = 0, int? end]);

  /// Writes a string to the file using the given [Encoding].
  ///
  /// Returns a `Future<RandomAccessFile>` that completes with this
  /// random access file when the write completes.
  Future<RandomAccessFile> writeString(String string,
      {Encoding encoding = utf8});

  /// Gets the current byte position in the file.
  ///
  /// Returns a `Future<int>` that completes with the position.
  Future<int> position();

  /// Sets the byte position in the file.
  ///
  /// Returns a `Future<RandomAccessFile>` that completes with this
  /// random access file when the position has been set.
  Future<RandomAccessFile> setPosition(int position);

  /// Truncates (or extends) the file to [length] bytes.
  ///
  /// Returns a `Future<RandomAccessFile>` that completes with this
  /// random access file when the truncation has been performed.
  Future<RandomAccessFile> truncate(int length);

  /// Gets the length of the file.
  ///
  /// Returns a `Future<int>` that completes with the length in bytes.
  Future<int> length();

  /// Flushes the contents of the file to disk.
  ///
  /// Returns a `Future<RandomAccessFile>` that completes with this
  /// random access file when the flush operation completes.
  Future<RandomAccessFile> flush();

  /// The path of the file underlying this random access file.
  String get path;
}
