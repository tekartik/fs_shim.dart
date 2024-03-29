/// {@canonicalFor fs_io_stub.fileSystemIo}
library fs_shim;

export 'fs.dart';
export 'fs_memory.dart' show fileSystemMemory;
export 'src/default/fs_default.dart' show fileSystemDefault;
export 'src/io/fs_io.dart' show fileSystemIo;
export 'src/web_interop/fs_web.dart' show fileSystemWeb;
