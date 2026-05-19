import 'dart:io';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class PdfViewerWidget extends StatefulWidget {
  final File file;

  const PdfViewerWidget({super.key, required this.file});

  @override
  State<PdfViewerWidget> createState() => _PdfViewerWidgetState();
}

class _PdfViewerWidgetState extends State<PdfViewerWidget> {
  late PdfViewerController _pdfViewerController;
  late PdfTextSearchResult _searchResult;
  bool _isSearchVisible = false;
  bool _isNightMode = false;
  int _currentPage = 1;
  int _totalPages = 0;
  final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    _pdfViewerController = PdfViewerController();
    _searchResult = PdfTextSearchResult();
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showBookmarks() {
    _pdfViewerKey.currentState?.openBookmarkView();
  }

  void _showJumpToPageDialog() {
    final TextEditingController pageController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Jump to Page'),
        content: TextField(
          controller: pageController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: 'Enter page number (1-$_totalPages)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final int? page = int.tryParse(pageController.text);
              if (page != null && page > 0 && page <= _totalPages) {
                _pdfViewerController.jumpToPage(page);
                Navigator.pop(context);
              }
            },
            child: const Text('Go'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget viewer = SfPdfViewer.file(
      widget.file,
      key: _pdfViewerKey,
      controller: _pdfViewerController,
      onDocumentLoaded: (PdfDocumentLoadedDetails details) {
        setState(() {
          _totalPages = details.document.pages.count;
        });
      },
      onPageChanged: (PdfPageChangedDetails details) {
        setState(() {
          _currentPage = details.newPageNumber;
        });
      },
    );

    if (_isNightMode) {
      viewer = ColorFiltered(
        colorFilter: const ColorFilter.matrix(<double>[
          -1.0, 0.0, 0.0, 0.0, 255.0,
          0.0, -1.0, 0.0, 0.0, 255.0,
          0.0, 0.0, -1.0, 0.0, 255.0,
          0.0, 0.0, 0.0, 1.0, 0.0,
        ]),
        child: viewer,
      );
    }

    return Column(
      children: [
        if (_isSearchVisible) _buildSearchToolbar(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Page $_currentPage of $_totalPages',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.bookmark),
                    onPressed: _showBookmarks,
                    tooltip: 'Bookmarks',
                  ),
                  TextButton(
                    onPressed: _totalPages > 0 ? _showJumpToPageDialog : null,
                    child: const Text('Jump to Page'),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              viewer,
              Positioned(
                bottom: 16,
                right: 16,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FloatingActionButton(
                      heroTag: 'nightMode',
                      mini: true,
                      onPressed: () {
                        setState(() {
                          _isNightMode = !_isNightMode;
                        });
                      },
                      child: Icon(_isNightMode ? Icons.light_mode : Icons.dark_mode),
                    ),
                    const SizedBox(height: 8),
                    FloatingActionButton(
                      heroTag: 'search',
                      mini: true,
                      onPressed: () {
                        setState(() {
                          _isSearchVisible = !_isSearchVisible;
                          if (!_isSearchVisible) {
                            _searchResult.clear();
                            _searchController.clear();
                          }
                        });
                      },
                      child: Icon(_isSearchVisible ? Icons.close : Icons.search),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSearchToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Theme.of(context).cardColor,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Find in PDF...',
                border: InputBorder.none,
              ),
              onSubmitted: (value) {
                _searchResult = _pdfViewerController.searchText(value);
                setState(() {});
              },
            ),
          ),
          if (_searchResult.hasResult) ...[
            Text(
              '${_searchResult.currentInstanceIndex} / ${_searchResult.totalInstanceCount}',
              style: const TextStyle(fontSize: 12),
            ),
            IconButton(
              icon: const Icon(Icons.keyboard_arrow_up),
              onPressed: () {
                _searchResult.previousInstance();
                setState(() {});
              },
            ),
            IconButton(
              icon: const Icon(Icons.keyboard_arrow_down),
              onPressed: () {
                _searchResult.nextInstance();
                setState(() {});
              },
            ),
          ],
        ],
      ),
    );
  }
}
