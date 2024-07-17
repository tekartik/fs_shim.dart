import 'dart:typed_data';

import 'package:dev_test/test.dart';
import 'package:fs_shim/fs_idb.dart';
import 'package:fs_shim/fs_shim.dart';
import 'package:tekartik_fs_test/test_common.dart';

void main() {
  fsPerfTestGroup(fileSystemDefault);
  tearDownAll(() {
    print(fsPerfMarkdownResult());
  });
}

class FsPerfParam {
  final int count;
  final int size;
  late final Uint8List data;

  FsPerfParam(this.count, this.size) {
    data = Uint8List.fromList(List<int>.generate(size, (index) => index % 256));
  }

  @override
  int get hashCode => count + size;

  @override
  String toString() => '$count times $size bytes';

  @override
  bool operator ==(Object other) {
    if (other is FsPerfParam) {
      if (other.count != count) {
        return false;
      }
      if (other.size != size) {
        return false;
      }
      return true;
    }
    return super == other;
  }
}

class _ParamPerfResult {
  Duration? write;
  Duration? read;
  Duration? rafWrite;
  Duration? rafRead;
}

class _FsPerfResult {
  final _paramResult = <FsPerfParam, _ParamPerfResult>{};

  _ParamPerfResult operator [](FsPerfParam param) =>
      _paramResult[param] ??= _ParamPerfResult();
}

var _split = 10;

const _kWrite = 0;
const _kRafWrite = 1;
const _kRead = 2;
const _kRafRead = 3;
var _perfResult = <FileSystem, _FsPerfResult>{};

String fsPerfMarkdownResult() {
  // Get params from first items

  var params = _perfResult.values.first._paramResult.keys;
  var fsList = _perfResult.keys;
  // First line, fs
  var sb = StringBuffer('');
  sb.writeln(
      '| action | count | size | ${fsList.map((e) => e.debugName).join(' |')} |');
  sb.writeln(
      '| ------ | ----- | ---- | ${fsList.map((e) => '---').join(' |')} |');
  for (var i = 0; i < 4; i++) {
    String? label;

    switch (i) {
      case _kWrite:
        label = 'write';
        break;
      case _kRafWrite:
        label = 'random write';
        break;
      case _kRead:
        label = 'read';
        break;
      case _kRafRead:
        label = 'random read';
        break;
    }
    for (var param in params) {
      var size = param.size;
      switch (i) {
        case _kRafWrite:
        case _kRafRead:
          size = (param.size ~/ _split) + 1;
          break;
      }

      sb.write('| $label | ${param.count} | $size |');

      Duration? value;
      for (var fs in fsList) {
        var fsResult = _perfResult[fs]!;
        var paramResult = fsResult[param];
        switch (i) {
          case _kWrite:
            value = paramResult.write;
            break;
          case _kRafWrite:
            value = paramResult.rafWrite;
            break;
          case _kRead:
            value = paramResult.read;
            break;
          case _kRafRead:
            value = paramResult.rafRead;
            break;
        }
        sb.write(' ${value?.inMilliseconds ?? ''} |');
      }
      sb.writeln();
    }
  }
  return sb.toString();
}

// Skip test too long
bool _skipTest(FileSystem fs, int size) {
  if (size > 2 * 1024 * 1024 &&
      fs.hasIdbOptions &&
      fs.idbOptions.hasPageSize &&
      fs.idbOptions.filePageSize < 256) {
    return true;
  }
  return false;
}

void fsPerfTestGroup(FileSystem fs, {List<FsPerfParam>? params}) {
  var fsPerfResult = _perfResult[fs] ??= _FsPerfResult();
  test('write_read_${fs.debugName}', () async {
    var file =
        fs.file(fs.path.join('.dart_tool', 'tekartik_fs_test', 'perf', 'file'));
    await file.parent.create(recursive: true);

    params ??= [
      FsPerfParam(100, 2),
      FsPerfParam(100, 1024),
      FsPerfParam(10, 64 * 1024),
      FsPerfParam(5, 1024 * 1024),
      FsPerfParam(1, 10 * 1024 * 1024),
    ];
    for (var param in params!) {
      if (_skipTest(fs, param.size)) {
        continue;
      }
      try {
        await file.delete(recursive: true);
      } catch (_) {}
      var paramResult = fsPerfResult[param];
      print(fs.debugName);
      var sw = Stopwatch();
      sw.start();
      for (var i = 0; i < param.count; i++) {
        await file.writeAsBytes(param.data);
      }

      paramResult.write = sw.elapsed;

      var split = 10;
      var chunkSize = (param.size ~/ split) + 1;

      // raf
      if (fs.supportsRandomAccess) {
        if (!_skipTest(fs, chunkSize)) {
          sw
            ..reset()
            ..start();
          var raf = await file.open(mode: FileMode.append);
          for (var i = 0; i < param.count; i++) {
            await raf.setPosition((i * chunkSize) % param.size);
            await raf.writeFrom(param.data, 0, chunkSize);
          }
          await raf.close();
          sw.stop();
          paramResult.rafWrite = sw.elapsed;
          print('raf write $param ${sw.elapsed}');
        }
      }

      sw
        ..reset()
        ..start();
      for (var i = 0; i < param.count; i++) {
        await file.readAsBytes();
      }
      sw.stop();
      paramResult.read = sw.elapsed;

      print('read $param ${sw.elapsed}');

      // raf
      if (fs.supportsRandomAccess) {
        if (!_skipTest(fs, chunkSize)) {
          sw
            ..reset()
            ..start();
          var raf = await file.open(mode: FileMode.append);
          for (var i = 0; i < param.count; i++) {
            await raf.setPosition((i * chunkSize) % param.size);
            var buffer = Uint8List(chunkSize);
            await raf.readInto(buffer, 0, chunkSize);
          }
          await raf.close();
          sw.stop();
          paramResult.rafRead = sw.elapsed;
          print('raf read $param ${sw.elapsed}');
        }
      }
    }
  }, timeout: const Timeout(Duration(minutes: 5)));
}
