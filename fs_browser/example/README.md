# fs_browser examples

## opfs_directory_picker

Pick a local directory using `window.showDirectoryPicker()` (File System
Access API, Chromium-only) and list its content (with stat) through the
fs_shim API (`fileSystemOpfsWebWithRootHandle`).

Run with:

```bash
dart run build_runner serve example:8080
```

then open <http://localhost:8080/opfs_directory_picker/>.

## opfs_handle_sdb

Pick a file or a directory (Chromium-only) or use a file of the OPFS (every
browser) and save its handle in an sdb (IndexedDB) database
(`SdbNativeValue(handle.jsObject)`, idb_shim 2.11.0 or later). After a reload,
the handle is restored (`FileSystemOpfsWebFileHandle.fromJsObject`), its
permission queried and requested again if needed
(`FileSystemOpfsWeb.queryPermission` and `requestPermission`) before reading it
through the fs_shim API.

Then open <http://localhost:8080/opfs_handle_sdb/>.
