export 'fs_web_stub.dart'
    if (dart.library.js_interop) 'fs_web_impl.dart'
    if (dart.library.io) 'fs_web_io.dart';
