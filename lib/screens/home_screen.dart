import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pdf_reader/services/file_service.dart';
import 'package:pdf_reader/services/preference_service.dart';
import 'package:pdf_reader/screens/viewer_screen.dart';
import 'package:pdf_reader/core/constants.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FileService _fileService = FileService();
  final PreferenceService _preferenceService = PreferenceService();

  List<File> _allFiles = [];
  List<File> _filteredFiles = [];
  List<String> _favoritePaths = [];
  List<String> _recentPaths = [];

  String _selectedFilter = 'All';
  String _searchQuery = '';
  bool _isLoading = true;
  bool _isSearching = false;
  bool _isGridView = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final files = await _fileService.discoverFiles();
    final favorites = await _preferenceService.getFavorites();
    final recents = await _preferenceService.getRecents();

    setState(() {
      _allFiles = files;
      _favoritePaths = favorites;
      _recentPaths = recents;
      _applyFilter();
      _isLoading = false;
    });
  }

  void _applyFilter() {
    setState(() {
      List<File> baseList = _allFiles;

      if (_selectedFilter == 'Favorites') {
        baseList = _allFiles.where((f) => _favoritePaths.contains(f.path)).toList();
      } else if (_selectedFilter == 'Recents') {
        // Sort by recents order
        baseList = [];
        for (var path in _recentPaths) {
          final file = _allFiles.firstWhere((f) => f.path == path, orElse: () => File(''));
          if (file.path.isNotEmpty) {
            baseList.add(file);
          }
        }
      } else if (_selectedFilter != 'All') {
        baseList = _allFiles.where((file) {
          final ext = _fileService.getFileExtension(file.path);
          switch (_selectedFilter) {
            case 'PDF':
              return AppConstants.pdfExtensions.contains(ext);
            case 'Word':
              return AppConstants.docxExtensions.contains(ext);
            case 'PPT':
              return ext == 'pptx';
            case 'Excel':
              return ext == 'xlsx';
            default:
              return false;
          }
        }).toList();
      }

      if (_searchQuery.isNotEmpty) {
        _filteredFiles = baseList.where((file) {
          final name = file.path.split('/').last.toLowerCase();
          return name.contains(_searchQuery.toLowerCase());
        }).toList();
      } else {
        _filteredFiles = baseList;
      }
    });
  }

  Future<void> _toggleFavorite(String filePath) async {
    await _preferenceService.toggleFavorite(filePath);
    final favorites = await _preferenceService.getFavorites();
    setState(() {
      _favoritePaths = favorites;
      if (_selectedFilter == 'Favorites') {
        _applyFilter();
      }
    });
  }

  Future<void> _pickFile() async {
    final file = await _fileService.pickDocument();
    if (file != null) {
      if (!_allFiles.any((f) => f.path == file.path)) {
        setState(() {
          _allFiles.insert(0, file);
          _applyFilter();
        });
      }
      _openFile(file);
    }
  }

  void _openFile(File file) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ViewerScreen(file: file),
      ),
    ).then((_) => _loadData()); // Reload to update recents
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search documents...',
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                    _applyFilter();
                  });
                },
              )
            : const Text('DocReader'),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _isSearching = false;
                  _searchQuery = '';
                  _searchController.clear();
                  _applyFilter();
                } else {
                  _isSearching = true;
                }
              });
            },
          ),
          IconButton(
            icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
            onPressed: () {
              setState(() {
                _isGridView = !_isGridView;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredFiles.isEmpty
                    ? _buildEmptyState()
                    : _isGridView
                        ? _buildFilesGrid()
                        : _buildFilesList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _pickFile,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFilterBar() {
    final filters = ['All', 'Favorites', 'Recents', 'PDF', 'Word', 'PPT', 'Excel'];
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = _selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(filter),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedFilter = filter;
                  _applyFilter();
                });
              },
              selectedColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
              checkmarkColor: Theme.of(context).primaryColor,
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty
                ? 'No matches found for "$_searchQuery"'
                : 'No $_selectedFilter files found',
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildFilesList() {
    return ListView.builder(
      itemCount: _filteredFiles.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final file = _filteredFiles[index];
        final extension = _fileService.getFileExtension(file.path);
        final isFavorite = _favoritePaths.contains(file.path);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: _buildFileIcon(extension),
            title: Text(
              file.path.split('/').last,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: Text(
              '${(file.lengthSync() / 1024).toStringAsFixed(1)} KB',
              style: TextStyle(color: Colors.grey[600]),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: isFavorite ? Colors.red : null,
                  ),
                  onPressed: () => _toggleFavorite(file.path),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
            onTap: () => _openFile(file),
          ),
        );
      },
    );
  }

  Widget _buildFilesGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.85,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _filteredFiles.length,
      itemBuilder: (context, index) {
        final file = _filteredFiles[index];
        final extension = _fileService.getFileExtension(file.path);
        final isFavorite = _favoritePaths.contains(file.path);

        return Card(
          child: InkWell(
            onTap: () => _openFile(file),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Center(child: _buildFileIcon(extension, size: 48)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    file.path.split('/').last,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${(file.lengthSync() / 1024).toStringAsFixed(0)} KB',
                        style: TextStyle(color: Colors.grey[600], fontSize: 11),
                      ),
                      IconButton(
                        icon: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: isFavorite ? Colors.red : null,
                          size: 18,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => _toggleFavorite(file.path),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFileIcon(String extension, {double size = 24}) {
    IconData iconData;
    Color color;
    switch (extension) {
      case 'pdf':
        iconData = Icons.picture_as_pdf;
        color = Colors.red;
        break;
      case 'docx':
        iconData = Icons.description;
        color = Colors.blue;
        break;
      case 'pptx':
        iconData = Icons.slideshow;
        color = Colors.orange;
        break;
      case 'xlsx':
        iconData = Icons.table_chart;
        color = Colors.green;
        break;
      default:
        iconData = Icons.insert_drive_file;
        color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(iconData, color: color, size: size),
    );
  }
}
