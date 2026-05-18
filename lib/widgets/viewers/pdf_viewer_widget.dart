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
  bool _isVerticalScroll = true;
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
        Expanded(
          child: Stack(
            children: [
              _isNightMode
                  ? ColorFiltered(
                      colorFilter: const ColorFilter.matrix([
                        -1, 0, 0, 0, 255, // Red
                        0, -1, 0, 0, 255, // Green
                        0, 0, -1, 0, 255, // Blue
                        0, 0, 0, 1, 0, // Alpha
                      ]),
                      child: SfPdfViewer.file(
                        widget.file,
                        controller: _pdfViewerController,
                        scrollDirection: _isVerticalScroll
                            ? PdfScrollDirection.vertical
                            : PdfScrollDirection.horizontal,
                      ),
                    )
                  : SfPdfViewer.file(
                      widget.file,
                      controller: _pdfViewerController,
                      scrollDirection: _isVerticalScroll
                          ? PdfScrollDirection.vertical
                          : PdfScrollDirection.horizontal,
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
            hintText: 'Enter page number (1 - ${_pdfViewerController.pageCount})',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final page = int.tryParse(pageController.text);
              if (page != null && page > 0 && page <= _pdfViewerController.pageCount) {
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
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'night_mode') {
                setState(() => _isNightMode = !_isNightMode);
              } else if (value == 'jump_to_page') {
                _showJumpToPageDialog();
              } else if (value == 'scroll_direction') {
                setState(() => _isVerticalScroll = !_isVerticalScroll);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'night_mode',
                child: Row(
                  children: [
                    Icon(_isNightMode ? Icons.light_mode : Icons.dark_mode),
                    const SizedBox(width: 8),
                    Text(_isNightMode ? 'Light Mode' : 'Night Mode'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'scroll_direction',
                child: Row(
                  children: [
                    Icon(_isVerticalScroll ? Icons.swap_horiz : Icons.swap_vert),
                    const SizedBox(width: 8),
                    Text(_isVerticalScroll ? 'Horizontal Scroll' : 'Vertical Scroll'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'jump_to_page',
                child: Row(
                  children: [
                    Icon(Icons.directions),
                    const SizedBox(width: 8),
                    Text('Jump to Page'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
