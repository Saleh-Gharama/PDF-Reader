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
  int _totalPage = 0;
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

  Widget _buildPdfViewer() {
    final pdfViewer = SfPdfViewer.file(
      widget.file,
      key: _pdfViewerKey,
      controller: _pdfViewerController,
      onPageChanged: (PdfPageChangedDetails details) {
        setState(() {
          _currentPage = details.newPageNumber;
        });
      },
      onDocumentLoaded: (PdfDocumentLoadedDetails details) {
        setState(() {
          _totalPage = details.document.pages.count;
        });
      },
    );

    if (_isNightMode) {
      return ColorFiltered(
        colorFilter: const ColorFilter.matrix([
          -1.0, 0.0, 0.0, 0.0, 255.0,
          0.0, -1.0, 0.0, 0.0, 255.0,
          0.0, 0.0, -1.0, 0.0, 255.0,
          0.0, 0.0, 0.0, 1.0, 0.0
        ]),
        child: pdfViewer,
      );
    }
    return pdfViewer;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (_isSearchVisible)
          _buildSearchToolbar(),
        Expanded(
          child: Stack(
            children: [
              _buildPdfViewer(),
              if (_totalPage > 0)
                Positioned(
                  bottom: 16,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Page $_currentPage of $_totalPage',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ),
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

  Widget _buildSearchToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
          ),
          IconButton(
            icon: const Icon(Icons.bookmark),
            onPressed: () {
              _pdfViewerKey.currentState?.openBookmarkView();
            },
          ),
          IconButton(
            icon: const Icon(Icons.input),
            onPressed: () async {
              final int? page = await _showJumpToPageDialog();
              if (page != null && page > 0 && page <= _totalPage) {
                _pdfViewerController.jumpToPage(page);
              }
            },
          ),
          const VerticalDivider(),
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

  Future<int?> _showJumpToPageDialog() async {
    int? pageNumber;
    return showDialog<int>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Jump to Page'),
          content: TextField(
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'Enter page (1-$_totalPage)',
            ),
            onChanged: (value) {
              pageNumber = int.tryParse(value);
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, pageNumber),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
