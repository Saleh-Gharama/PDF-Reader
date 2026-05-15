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
  String _selectedFilter = 'All';
  bool _isLoading = true;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    setState(() => _isLoading = true);
    final files = await _fileService.discoverFiles();
    _allFiles = files;
    await _applyFilter();
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _applyFilter() async {
    List<File> filtered = [];
    final query = _searchController.text.toLowerCase();

    if (_selectedFilter == 'Favorites') {
      final favPaths = await _preferenceService.getFavorites();
      filtered = _allFiles.where((f) => favPaths.contains(f.path)).toList();
    } else if (_selectedFilter == 'Recents') {
      final recentPaths = await _preferenceService.getRecents();
      // To maintain order of recents, we map paths to files
      filtered = recentPaths
          .map((path) => _allFiles.firstWhere((f) => f.path == path,
              orElse: () => File(path)))
          .where((f) => f.existsSync())
          .toList();
    } else {
      filtered = _allFiles.where((file) {
        final ext = _fileService.getFileExtension(file.path);
        if (_selectedFilter == 'All') return true;
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

    if (query.isNotEmpty) {
      filtered = filtered.where((file) {
        return file.path.split('/').last.toLowerCase().contains(query);
      }).toList();
    }

    setState(() {
      _filteredFiles = filtered;
    });
  }

  Future<void> _pickFile() async {
    final file = await _fileService.pickDocument();
    if (file != null) {
      if (!_allFiles.any((f) => f.path == file.path)) {
        setState(() {
          _allFiles.insert(0, file);
        });
        await _applyFilter();
      }
      _openFile(file);
    }
  }

  void _openFile(File file) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ViewerScreen(file: file),
      ),
    );
    // Refresh list in case favorites changed
    _applyFilter();
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
                  hintText: 'Search files...',
                  border: InputBorder.none,
                ),
                onChanged: (_) => _applyFilter(),
              )
            : const Text('DocReader'),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  _applyFilter();
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFiles,
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
    final filters = ['All', 'PDF', 'Word', 'PPT', 'Excel', 'Favorites', 'Recents'];
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
            'No $_selectedFilter files found',
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
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _openFile(file),
          ),
        );
      },
    );
  }

  Widget _buildFileIcon(String extension) {
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
      child: Icon(iconData, color: color),
    );
  }
}
