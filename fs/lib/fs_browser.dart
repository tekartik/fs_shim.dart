/// File systems on IndexedDB in the browser ([fileSystemWeb],
/// [fileSystemWebNoPaging], [getFileSystemWeb], [newFileSystemWeb]), web
/// only: reading them on io throws `UnimplementedError`.
library;

export 'package:fs_shim/src/web_interop/fs_web.dart'
    show
        fileSystemWeb,
        fileSystemWebNoPaging,
        getFileSystemWeb,
        newFileSystemWeb;

/// @nodoc
export 'fs_idb.dart';
