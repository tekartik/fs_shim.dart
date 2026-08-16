import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fs_shim/fs.dart' as fs;
import 'package:fs_shim/fs_memory.dart';
import 'package:path_provider/path_provider.dart';
import 'src/platform_helper.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FS Shim Explorer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF111115),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF6366F1), // Indigo
          secondary: Color(0xFFA855F7), // Purple
          surface: Color(0xFF1E1E24),
          error: Color(0xFFEF4444), // Rose
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF1E1E24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFF2E2E38), width: 1),
          ),
          elevation: 4,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF16161C),
          elevation: 0,
          centerTitle: true,
        ),
      ),
      home: const MainExplorerScreen(),
    );
  }
}

class MainExplorerScreen extends StatefulWidget {
  const MainExplorerScreen({super.key});

  @override
  State<MainExplorerScreen> createState() => _MainExplorerScreenState();
}

class _MainExplorerScreenState extends State<MainExplorerScreen> {
  // Active file system state
  fs.FileSystem? _fs;
  String? _fsType; // 'memory', 'io', 'web', 'opfs'
  String? _fsDisplayName;
  String _currentPath = '/';
  String _rootPath = '/';

  // Explorer file list state
  List<fs.FileSystemEntity> _entities = [];
  Map<String, fs.FileStat> _stats = {};
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';

  // Config controllers for selection screen
  final TextEditingController _dbNameController = TextEditingController(
    text: 'fs_shim_web',
  );
  final TextEditingController _ioPathController = TextEditingController();

  @override
  void dispose() {
    _dbNameController.dispose();
    _ioPathController.dispose();
    super.dispose();
  }

  // Formatting helper for file sizes
  String _formatSize(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    var i = (log(bytes) / log(1024)).floor();
    return '${(bytes / pow(1024, i)).toStringAsFixed(1)} ${suffixes[i]}';
  }

  // Formatting helper for DateTimes
  String _formatDate(DateTime dt) {
    return '${dt.year.toString().padLeft(4, '0')}-'
        '${dt.month.toString().padLeft(2, '0')}-'
        '${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }

  // Load standard system paths for IO FS convenience
  Future<void> _setIoDirectory(String type) async {
    try {
      String? path;
      if (type == 'documents') {
        final dir = await getApplicationDocumentsDirectory();
        path = dir.path;
      } else if (type == 'temp') {
        final dir = await getTemporaryDirectory();
        path = dir.path;
      } else if (type == 'appSupport') {
        final dir = await getApplicationSupportDirectory();
        path = dir.path;
      }
      if (path != null) {
        setState(() {
          _ioPathController.text = path!;
        });
      }
    } catch (e) {
      _showSnackbar('Error resolving system directory: $e', isError: true);
    }
  }

  // Pick a directory path for IO FS
  Future<void> _pickIoDirectory() async {
    try {
      final path = await pickDirectoryPath();
      if (path != null) {
        setState(() {
          _ioPathController.text = path;
        });
      }
    } catch (e) {
      _showSnackbar('Directory picker error: $e', isError: true);
    }
  }

  // Initialize selected file system
  Future<void> _initializeFileSystem({
    required String type,
    String? ioPath,
    String? webDbName,
    bool useOpfsPicker = false,
  }) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      fs.FileSystem fsInstance;
      String displayName = '';
      String rootPath = '/';

      switch (type) {
        case 'memory':
          fsInstance = newFileSystemMemory();
          displayName = 'In-Memory File System';
          rootPath = '/';
          break;

        case 'io':
          if (ioPath == null || ioPath.trim().isEmpty) {
            throw ArgumentError('Please specify or pick a directory path.');
          }
          // Fetch ioFileSystem via platform helper
          fsInstance = getIoFileSystem();
          displayName = 'Host IO File System';
          rootPath = ioPath;
          break;

        case 'web':
          final dbName = webDbName ?? 'fs_shim_web';
          fsInstance = getWebFileSystem();
          displayName = 'Web IndexedDB ($dbName)';
          rootPath = '/';
          break;

        case 'opfs':
          if (useOpfsPicker) {
            final pickedFs = await selectOpfsDirectory();
            if (pickedFs == null) {
              // Cancelled
              setState(() {
                _isLoading = false;
              });
              return;
            }
            fsInstance = pickedFs;
            displayName = 'OPFS Local Directory';
          } else {
            fsInstance = getOpfsFileSystem();
            displayName = 'OPFS Sandbox Root';
          }
          rootPath = '/';
          break;

        default:
          throw UnsupportedError('Unsupported filesystem type: $type');
      }

      setState(() {
        _fs = fsInstance;
        _fsType = type;
        _fsDisplayName = displayName;
        _rootPath = rootPath;
        _currentPath = rootPath;
      });

      await _refreshDirectory();
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
      _showSnackbar(e.toString(), isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Refresh current directory listing and stats
  Future<void> _refreshDirectory() async {
    final filesystem = _fs;
    if (filesystem == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final dir = filesystem.directory(_currentPath);

      // Ensure the path exists for native filesystems
      if (_fsType == 'io' && _currentPath == _rootPath) {
        if (!await dir.exists()) {
          await dir.create(recursive: true);
        }
      }

      final stream = dir.list(followLinks: false);
      final List<fs.FileSystemEntity> rawEntities = await stream.toList();

      // Collect stats
      final Map<String, fs.FileStat> tempStats = {};
      for (final entity in rawEntities) {
        try {
          final stat = await entity.stat();
          tempStats[entity.path] = stat;
        } catch (e) {
          debugPrint('Error getting stat for ${entity.path}: $e');
        }
      }

      // Sort: Directories first (alphabetical), then Files (alphabetical)
      rawEntities.sort((a, b) {
        final aIsDir =
            tempStats[a.path]?.type == fs.FileSystemEntityType.directory;
        final bIsDir =
            tempStats[b.path]?.type == fs.FileSystemEntityType.directory;

        if (aIsDir && !bIsDir) return -1;
        if (!aIsDir && bIsDir) return 1;

        final aName = filesystem.path.basename(a.path).toLowerCase();
        final bName = filesystem.path.basename(b.path).toLowerCase();
        return aName.compareTo(bName);
      });

      setState(() {
        _entities = rawEntities;
        _stats = tempStats;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Navigate to folder
  void _navigateToFolder(String path) {
    setState(() {
      _currentPath = path;
      _searchQuery = '';
    });
    _refreshDirectory();
  }

  // Navigate up
  void _navigateUp() {
    final filesystem = _fs;
    if (filesystem == null) return;

    if (_currentPath == _rootPath || _currentPath == '/') {
      return;
    }

    final parentPath = filesystem.path.dirname(_currentPath);
    _navigateToFolder(parentPath);
  }

  // Snackbar notifications
  void _showSnackbar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Create folder dialog
  Future<void> _showCreateFolderDialog() async {
    final filesystem = _fs;
    if (filesystem == null) return;

    final controller = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Folder'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter folder name',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (result == true && controller.text.trim().isNotEmpty) {
      final name = controller.text.trim();
      final newDirPath = filesystem.path.join(_currentPath, name);
      try {
        await filesystem.directory(newDirPath).create(recursive: true);
        _showSnackbar('Folder "$name" created.');
        _refreshDirectory();
      } catch (e) {
        _showSnackbar('Error creating folder: $e', isError: true);
      }
    }
  }

  // Create test text file dialog
  Future<void> _showCreateFileDialog() async {
    final filesystem = _fs;
    if (filesystem == null) return;

    final nameController = TextEditingController();
    final contentController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Text File'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                hintText: 'file.txt',
                labelText: 'File Name',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: contentController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Write text here...',
                labelText: 'Content',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (result == true && nameController.text.trim().isNotEmpty) {
      final name = nameController.text.trim();
      final content = contentController.text;
      final filePath = filesystem.path.join(_currentPath, name);
      try {
        final file = filesystem.file(filePath);
        await file.create(recursive: true);
        await file.writeAsString(content);
        _showSnackbar('File "$name" created.');
        _refreshDirectory();
      } catch (e) {
        _showSnackbar('Error creating file: $e', isError: true);
      }
    }
  }

  // Upload/import file to current directory
  Future<void> _uploadFile() async {
    final filesystem = _fs;
    if (filesystem == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final pickedFile = await FilePicker.pickFile(type: FileType.any);

      if (pickedFile != null) {
        final fileBytes = await pickedFile.readAsBytes();

        final targetPath = filesystem.path.join(_currentPath, pickedFile.name);
        final file = filesystem.file(targetPath);

        await file.create(recursive: true);
        await file.writeAsBytes(fileBytes);

        _showSnackbar('Uploaded "${pickedFile.name}" successfully!');
        _refreshDirectory();
      }
    } catch (e) {
      _showSnackbar('Upload failed: $e', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Download a file to host OS
  Future<void> _downloadFile(fs.File file) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final filesystem = _fs!;
      final filename = filesystem.path.basename(file.path);
      final bytes = await file.readAsBytes();

      // Trigger download/save using platform helper
      await saveFile(name: filename, bytes: bytes);
      _showSnackbar('Downloaded "$filename" successfully.');
    } catch (e) {
      _showSnackbar('Download failed: $e', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // View/Preview a text file
  Future<void> _previewFile(fs.File file) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final filesystem = _fs!;
      final filename = filesystem.path.basename(file.path);
      final bytes = await file.readAsBytes();

      String previewText;
      bool isBinary = false;
      try {
        previewText = const Utf8Decoder().convert(bytes);
        // Basic check for control characters to detect binaries
        final controlChars = previewText.codeUnits.where(
          (char) => char < 9 || (char > 13 && char < 32),
        );
        if (controlChars.length > previewText.length * 0.1) {
          isBinary = true;
        }
      } catch (e) {
        isBinary = true;
        previewText = '';
      }

      if (isBinary) {
        previewText =
            'This file appears to be a binary file. Previewing raw text is not supported.\n\nFile size: ${_formatSize(bytes.length)}';
      }

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(filename),
            content: SizedBox(
              width: min(MediaQuery.of(context).size.width * 0.8, 600),
              height: 400,
              child: SingleChildScrollView(
                child: isBinary
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Text(
                            previewText,
                            style: const TextStyle(color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : Card(
                        color: const Color(0xFF141419),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: SelectableText(
                            previewText,
                            style: const TextStyle(
                              fontFamily: 'Courier',
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
              if (!isBinary)
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _downloadFile(file);
                  },
                  icon: const Icon(Icons.download),
                  label: const Text('Download'),
                ),
            ],
          ),
        );
      }
    } catch (e) {
      _showSnackbar('Could not preview file: $e', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Delete entity
  Future<void> _deleteEntity(fs.FileSystemEntity entity) async {
    final filesystem = _fs;
    if (filesystem == null) return;

    final name = filesystem.path.basename(entity.path);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item'),
        content: Text(
          'Are you sure you want to delete "$name"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        await entity.delete(recursive: true);
        _showSnackbar('"$name" deleted successfully.');
        _refreshDirectory();
      } catch (e) {
        _showSnackbar('Delete failed: $e', isError: true);
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Reset file system state to selection screen
  void _resetFileSystem() {
    setState(() {
      _fs = null;
      _fsType = null;
      _fsDisplayName = null;
      _entities = [];
      _stats = {};
      _searchQuery = '';
      _errorMessage = null;
    });
  }

  // Main UI builder
  @override
  Widget build(BuildContext context) {
    final isSelected = _fs != null;

    return Scaffold(
      appBar: AppBar(
        title: isSelected
            ? Text(_fsDisplayName ?? 'Filesystem Explorer')
            : const Text('Select File System'),
        leading: isSelected
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: 'Disconnect File System',
                onPressed: _resetFileSystem,
              )
            : null,
        actions: isSelected
            ? [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh',
                  onPressed: _refreshDirectory,
                ),
              ]
            : null,
      ),
      body: isSelected ? _buildExplorerView() : _buildSelectionView(),
    );
  }

  // --- SELECTION VIEW ---
  Widget _buildSelectionView() {
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 700;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF16161C), Color(0xFF0F0F13)],
        ),
      ),
      child: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.folder_shared,
                    size: 80,
                    color: Color(0xFF6366F1),
                  ),
                  const SizedBox(height: 16),
                  const Center(
                    child: Text(
                      'FS Shim Explorer',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      'Select a filesystem to explore its contents',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  GridView.count(
                    crossAxisCount: isWide ? 2 : 1,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 20,
                    crossAxisSpacing: 20,
                    childAspectRatio: isWide ? 1.4 : 1.6,
                    children: [
                      // Card 1: Memory
                      _buildFsCard(
                        title: 'Memory File System',
                        subtitle:
                            'Temporary in-memory storage. Resets when app is closed.',
                        icon: Icons.memory,
                        gradient: const [Color(0xFF6366F1), Color(0xFF4F46E5)],
                        actionWidget: ElevatedButton(
                          onPressed: () =>
                              _initializeFileSystem(type: 'memory'),
                          child: const Text('Launch In-Memory'),
                        ),
                      ),

                      // Card 2: Web (IndexedDB) - Web only
                      if (isWebPlatform)
                        _buildFsCard(
                          title: 'Web (IndexedDB)',
                          subtitle: 'Persists in browser IndexedDB database.',
                          icon: Icons.storage,
                          gradient: const [
                            Color(0xFF0D9488),
                            Color(0xFF0F766E),
                          ],
                          actionWidget: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _dbNameController,
                                  style: const TextStyle(fontSize: 13),
                                  decoration: const InputDecoration(
                                    labelText: 'Database Name',
                                    isDense: true,
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: () => _initializeFileSystem(
                                  type: 'web',
                                  webDbName: _dbNameController.text,
                                ),
                                child: const Text('Launch'),
                              ),
                            ],
                          ),
                        ),

                      // Card 3: OPFS (Origin Private File System) - Web only
                      if (isWebPlatform)
                        _buildFsCard(
                          title: 'OPFS (Origin Private File System)',
                          subtitle:
                              'High performance sandboxed browser filesystem.',
                          icon: Icons.web_asset,
                          gradient: const [
                            Color(0xFFD97706),
                            Color(0xFFB45309),
                          ],
                          actionWidget: Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () =>
                                      _initializeFileSystem(type: 'opfs'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF374151),
                                  ),
                                  child: const Text(
                                    'Sandbox Root',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () => _initializeFileSystem(
                                    type: 'opfs',
                                    useOpfsPicker: true,
                                  ),
                                  child: const Text(
                                    'Open Picker',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Card 4: Host IO - Native only
                      if (!isWebPlatform)
                        _buildFsCard(
                          title: 'Native File System (IO)',
                          subtitle:
                              'Interact with directories on your machine.',
                          icon: Icons.computer,
                          gradient: const [
                            Color(0xFF059669),
                            Color(0xFF047857),
                          ],
                          actionWidget: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _ioPathController,
                                      style: const TextStyle(fontSize: 13),
                                      decoration: const InputDecoration(
                                        labelText: 'Directory Path',
                                        isDense: true,
                                        border: OutlineInputBorder(),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.folder_open),
                                    onPressed: _pickIoDirectory,
                                    tooltip: 'Browse...',
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    _buildPathChip('Temp', 'temp'),
                                    _buildPathChip('Documents', 'documents'),
                                    _buildPathChip('App Support', 'appSupport'),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton(
                                onPressed: () => _initializeFileSystem(
                                  type: 'io',
                                  ioPath: _ioPathController.text,
                                ),
                                child: const Text('Launch Directory'),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFsCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> gradient,
    required Widget actionWidget,
  }) {
    return Card(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              gradient[0].withValues(alpha: 0.08),
              gradient[1].withValues(alpha: 0.02),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 28, color: gradient[0]),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Text(
                subtitle,
                style: const TextStyle(fontSize: 13, color: Colors.grey),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 12),
            actionWidget,
          ],
        ),
      ),
    );
  }

  Widget _buildPathChip(String label, String key) {
    return Padding(
      padding: const EdgeInsets.only(right: 6.0),
      child: ChoiceChip(
        label: Text(label, style: const TextStyle(fontSize: 11)),
        selected: false,
        onSelected: (_) => _setIoDirectory(key),
      ),
    );
  }

  // --- EXPLORER VIEW ---
  Widget _buildExplorerView() {
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 800;

    // Filtered list based on search query
    final filteredEntities = _entities.where((entity) {
      final name = _fs!.path.basename(entity.path);
      return name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    final filesystem = _fs!;

    return Stack(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left sidebar on wide screens
            if (isWide)
              Container(
                width: 250,
                color: const Color(0xFF16161C),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'QUICK ACTIONS',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _showCreateFolderDialog,
                      icon: const Icon(Icons.create_new_folder, size: 18),
                      label: const Text('New Folder'),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: _showCreateFileDialog,
                      icon: const Icon(Icons.note_add, size: 18),
                      label: const Text('New Text File'),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: _uploadFile,
                      icon: const Icon(Icons.upload_file, size: 18),
                      label: const Text('Upload File'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    const Divider(),
                    const SizedBox(height: 10),
                    const Text(
                      'METADATA STATS',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildMetaRow(
                      'Folders',
                      '${_entities.whereType<fs.Directory>().length}',
                    ),
                    _buildMetaRow(
                      'Files',
                      '${_entities.whereType<fs.File>().length}',
                    ),
                    _buildMetaRow(
                      'Links',
                      '${_entities.whereType<fs.Link>().length}',
                    ),
                    const SizedBox(height: 20),
                    OutlinedButton.icon(
                      onPressed: _resetFileSystem,
                      icon: const Icon(Icons.power_settings_new),
                      label: const Text('Exit FS'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                      ),
                    ),
                  ],
                ),
              ),

            // Main directory browser area
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Breadcrumb navigation
                    _buildBreadcrumbs(),
                    const SizedBox(height: 16),

                    // Search and Action Bar (on mobile/narrow screens)
                    Row(
                      children: [
                        Expanded(
                          child: SearchBar(
                            hintText: 'Search current folder...',
                            onChanged: (val) {
                              setState(() {
                                _searchQuery = val;
                              });
                            },
                            leading: const Icon(
                              Icons.search,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                        if (!isWide) ...[
                          const SizedBox(width: 10),
                          IconButton(
                            icon: const Icon(
                              Icons.create_new_folder,
                              color: Colors.indigoAccent,
                            ),
                            onPressed: _showCreateFolderDialog,
                            tooltip: 'New Folder',
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.note_add,
                              color: Colors.indigoAccent,
                            ),
                            onPressed: _showCreateFileDialog,
                            tooltip: 'New Text File',
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.upload,
                              color: Colors.indigoAccent,
                            ),
                            onPressed: _uploadFile,
                            tooltip: 'Upload File',
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Explorer Table/List
                    Expanded(
                      child: _errorMessage != null
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.error_outline,
                                    color: Colors.redAccent,
                                    size: 48,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Error loading directory:\n$_errorMessage',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.redAccent,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: _refreshDirectory,
                                    child: const Text('Retry'),
                                  ),
                                ],
                              ),
                            )
                          : filteredEntities.isEmpty &&
                                _currentPath == _rootPath
                          ? _buildEmptyDirectoryWidget()
                          : Card(
                              margin: EdgeInsets.zero,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: ListView.builder(
                                  itemCount:
                                      (_currentPath != _rootPath ? 1 : 0) +
                                      filteredEntities.length,
                                  itemBuilder: (context, index) {
                                    // "Go Up" item
                                    if (_currentPath != _rootPath &&
                                        index == 0) {
                                      return ListTile(
                                        leading: const Icon(
                                          Icons.subdirectory_arrow_left,
                                          color: Colors.indigoAccent,
                                        ),
                                        title: const Text(
                                          '..',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        subtitle: const Text(
                                          'Parent Directory',
                                        ),
                                        onTap: _navigateUp,
                                      );
                                    }

                                    final entityIndex =
                                        _currentPath != _rootPath
                                        ? index - 1
                                        : index;
                                    final entity =
                                        filteredEntities[entityIndex];
                                    final name = filesystem.path.basename(
                                      entity.path,
                                    );
                                    final stat = _stats[entity.path];
                                    final isDir =
                                        stat?.type ==
                                        fs.FileSystemEntityType.directory;
                                    final isLink =
                                        stat?.type ==
                                        fs.FileSystemEntityType.link;

                                    IconData iconData =
                                        Icons.insert_drive_file_outlined;
                                    Color iconColor = Colors.grey;

                                    if (isDir) {
                                      iconData = Icons.folder;
                                      iconColor = const Color(0xFF6366F1);
                                    } else if (isLink) {
                                      iconData = Icons.link;
                                      iconColor = Colors.amber;
                                    }

                                    final sizeStr = (!isDir && stat != null)
                                        ? _formatSize(stat.size)
                                        : '';
                                    final dateStr = stat != null
                                        ? _formatDate(stat.modified)
                                        : '';

                                    return Container(
                                      decoration: const BoxDecoration(
                                        border: Border(
                                          bottom: BorderSide(
                                            color: Color(0xFF2E2E38),
                                            width: 0.5,
                                          ),
                                        ),
                                      ),
                                      child: ListTile(
                                        leading: Icon(
                                          iconData,
                                          color: iconColor,
                                        ),
                                        title: Text(
                                          name,
                                          style: TextStyle(
                                            fontWeight: isDir
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                          ),
                                        ),
                                        subtitle: Text(
                                          '${isDir
                                              ? 'Directory'
                                              : isLink
                                              ? 'Link'
                                              : 'File'} • $dateStr ${sizeStr.isNotEmpty ? '• $sizeStr' : ''}',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            // Preview / View File
                                            if (!isDir &&
                                                !isLink &&
                                                entity is fs.File)
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.visibility_outlined,
                                                  size: 20,
                                                ),
                                                color: Colors.greenAccent,
                                                tooltip: 'Preview File',
                                                onPressed: () =>
                                                    _previewFile(entity),
                                              ),
                                            // Download
                                            if (!isDir &&
                                                !isLink &&
                                                entity is fs.File)
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.download,
                                                  size: 20,
                                                ),
                                                color: const Color(0xFF6366F1),
                                                tooltip: 'Download File',
                                                onPressed: () =>
                                                    _downloadFile(entity),
                                              ),
                                            // Delete
                                            IconButton(
                                              icon: const Icon(
                                                Icons.delete_outline,
                                                size: 20,
                                              ),
                                              color: Colors.redAccent,
                                              tooltip: 'Delete',
                                              onPressed: () =>
                                                  _deleteEntity(entity),
                                            ),
                                          ],
                                        ),
                                        onTap: isDir
                                            ? () =>
                                                  _navigateToFolder(entity.path)
                                            : isLink
                                            ? () => _showSnackbar(
                                                'Links cannot be directly explored.',
                                              )
                                            : () => _previewFile(
                                                entity as fs.File,
                                              ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        if (_isLoading)
          Container(
            color: Colors.black54,
            child: const Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Processing file system operation...'),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyDirectoryWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.folder_open, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'This folder is empty',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Create folders, files, or upload existing files to get started.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton.icon(
                onPressed: _showCreateFolderDialog,
                icon: const Icon(Icons.create_new_folder),
                label: const Text('Create Folder'),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: _uploadFile,
                icon: const Icon(Icons.upload),
                label: const Text('Upload File'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Helper metadata row in sidebar
  Widget _buildMetaRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ],
      ),
    );
  }

  // Breadcrumbs builder
  Widget _buildBreadcrumbs() {
    final filesystem = _fs!;
    final pathContext = filesystem.path;

    // Split the current path relative to root path
    String relativePath = _currentPath;
    if (_currentPath.startsWith(_rootPath)) {
      relativePath = _currentPath.substring(_rootPath.length);
    }
    if (relativePath.startsWith('/') || relativePath.startsWith('\\')) {
      relativePath = relativePath.substring(1);
    }

    final segments = relativePath.isEmpty
        ? <String>[]
        : pathContext.split(relativePath);

    final List<Widget> widgets = [];

    // Root node
    widgets.add(
      InkWell(
        onTap: () => _navigateToFolder(_rootPath),
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 4.0),
          child: Text(
            _fsType == 'io'
                ? 'Root (${pathContext.basename(_rootPath)})'
                : 'Root',
            style: TextStyle(
              fontWeight: segments.isEmpty
                  ? FontWeight.bold
                  : FontWeight.normal,
              color: segments.isEmpty ? const Color(0xFF6366F1) : Colors.white,
            ),
          ),
        ),
      ),
    );

    String accumulatedPath = _rootPath;
    for (int i = 0; i < segments.length; i++) {
      widgets.add(
        const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
      );

      accumulatedPath = pathContext.join(accumulatedPath, segments[i]);
      final isLast = i == segments.length - 1;
      final folderName = segments[i];
      final currentAccumulated = accumulatedPath;

      widgets.add(
        InkWell(
          onTap: () => _navigateToFolder(currentAccumulated),
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 4.0),
            child: Text(
              folderName,
              style: TextStyle(
                fontWeight: isLast ? FontWeight.bold : FontWeight.normal,
                color: isLast ? const Color(0xFF6366F1) : Colors.white,
              ),
            ),
          ),
        ),
      );
    }

    return Card(
      margin: EdgeInsets.zero,
      color: const Color(0xFF16161C),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: widgets),
        ),
      ),
    );
  }
}
