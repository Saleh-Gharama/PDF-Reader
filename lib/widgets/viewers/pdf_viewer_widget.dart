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
  final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey();

  bool _isSearchVisible = false;
  bool _isNightMode = false;
  int _currentPage = 0;
  int _totalPageCount = 0;

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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (_isSearchVisible)
          _buildSearchToolbar(),
        _buildTopToolbar(),
        Expanded(
          child: Stack(
            children: [
              if (_isNightMode)
                ColorFiltered(
                  colorFilter: const ColorFilter.matrix([
                    -1.0, 0.0, 0.0, 0.0, 255.0,
                    0.0, -1.0, 0.0, 0.0, 255.0,
                    0.0, 0.0, -1.0, 0.0, 255.0,
                    0.0, 0.0, 0.0, 1.0, 0.0,
                  ]),
                  child: _buildViewer(),
                )
              else
                _buildViewer(),
              Positioned(
                bottom: 16,
                right: 16,
                child: FloatingActionButton(
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
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTopToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      color: Theme.of(context).cardColor,
      child: Row(
        children: [
          IconButton(
            icon: Icon(_isNightMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: () {
              setState(() {
                _isNightMode = !_isNightMode;
              });
            },
            tooltip: 'Night Mode',
          ),
          IconButton(
            icon: const Icon(Icons.input),
            onPressed: _showJumpToPageDialog,
            tooltip: 'Jump to Page',
          ),
          IconButton(
            icon: const Icon(Icons.bookmark),
            onPressed: () {
              _pdfViewerKey.currentState?.openBookmarkView();
            },
            tooltip: 'Bookmarks',
          ),
          const Spacer(),
          Text('Page $_currentPage of $_totalPageCount'),
        ],
      ),
    );
  }

  void _showJumpToPageDialog() {
    final TextEditingController pageController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Jump to Page'),
          content: TextField(
            controller: pageController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'Enter page (1-$_totalPageCount)',
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
                if (page != null && page > 0 && page <= _totalPageCount) {
                  _pdfViewerController.jumpToPage(page);
                  Navigator.pop(context);
                }
              },
              child: const Text('Go'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildViewer() {
    return SfPdfViewer.file(
      widget.file,
      key: _pdfViewerKey,
      controller: _pdfViewerController,
      onDocumentLoaded: (PdfDocumentLoadedDetails details) {
        setState(() {
          _totalPageCount = _pdfViewerController.pageCount;
          _currentPage = _pdfViewerController.pageNumber;
        });
      },
      onPageChanged: (PdfPageChangedDetails details) {
        setState(() {
          _currentPage = details.newPageNumber;
        });
      },
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
