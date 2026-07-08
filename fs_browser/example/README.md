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
