export 'fs_io_stub.dart'
    if (dart.library.io) 'fs_io_impl.dart'
    if (dart.library.html) 'fs_io_web.dart';
