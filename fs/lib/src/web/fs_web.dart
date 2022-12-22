import 'package:fs_shim/fs_browser.dart';
import 'package:fs_shim/fs_shim.dart';
import 'package:fs_shim/src/idb/idb_file_system.dart';

export 'fs_web_stub.dart'
    if (dart.library.html) 'fs_web_impl.dart'
    if (dart.library.io) 'fs_web_io.dart';

/// Web specific extesion
extension FileSystemWebExt on FileSystem {
  /// Use a specific pageSize
  FileSystem withWebOptions({required FileSystemIdbOptions options}) {
    return (this as IdbFileSystem).withOptionsImpl(options: options);
  }
}
