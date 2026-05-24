import 'dart:io';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:pdf_reader/services/preference_service.dart';

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
  final TextEditingController _searchController = TextEditingController();
  final PreferenceService _preferenceService = PreferenceService();
  List<PdfBookmark> _bookmarks = [];

  @override
  void initState() {
    _pdfViewerController = PdfViewerController();
    _searchResult = PdfTextSearchResult();
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _pdfViewerController.dispose();
    super.dispose();
  }

  void _onDocumentLoaded(PdfDocumentLoadedDetails details) async {
    setState(() {
      _bookmarks = [];
      for (int i = 0; i < details.document.bookmarks.count; i++) {
        _bookmarks.add(details.document.bookmarks[i]);
      }
    });

    final lastPage = await _preferenceService.getPageProgress(widget.file.path);
    if (lastPage > 1) {
      _pdfViewerController.jumpToPage(lastPage);
    }
  }

  void _onPageChanged(PdfPageChangedDetails details) {
    _preferenceService.savePageProgress(widget.file.path, details.newPageNumber);
  }

  void _showOutlineAndNavigation() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DefaultTabController(
          length: 2,
          child: Column(
            children: [
              const TabBar(
                tabs: [
                  Tab(icon: Icon(Icons.list), text: 'Outline'),
                  Tab(icon: Icon(Icons.input), text: 'Jump to Page'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildOutlineTab(),
                    _buildJumpToPageTab(),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOutlineTab() {
    if (_bookmarks.isEmpty) {
      return const Center(
        child: Text('No bookmarks found in this document'),
      );
    }
    return ListView.builder(
      itemCount: _bookmarks.length,
      itemBuilder: (context, index) {
        final bookmark = _bookmarks[index];
        return ListTile(
          title: Text(bookmark.title),
          onTap: () {
            Navigator.pop(context);
            _pdfViewerController.jumpToBookmark(bookmark);
          },
        );
      },
    );
  }

  Widget _buildJumpToPageTab() {
    final TextEditingController jumpController = TextEditingController();
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextField(
            controller: jumpController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Page Number',
              hintText: 'Enter page number (1-${_pdfViewerController.pageCount})',
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              final pageNumber = int.tryParse(jumpController.text);
              if (pageNumber != null &&
                  pageNumber > 0 &&
                  pageNumber <= _pdfViewerController.pageCount) {
                Navigator.pop(context);
                _pdfViewerController.jumpToPage(pageNumber);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Invalid page number')),
                );
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
    return Column(
      children: [
        if (_isSearchVisible)
          _buildSearchToolbar(),
        Expanded(
          child: Stack(
            children: [
              SfPdfViewer.file(
                widget.file,
                controller: _pdfViewerController,
                onDocumentLoaded: _onDocumentLoaded,
                onPageChanged: _onPageChanged,
              ),
              Positioned(
                bottom: 80,
                right: 16,
                child: FloatingActionButton(
                  mini: true,
                  heroTag: 'outline_btn',
                  onPressed: _showOutlineAndNavigation,
                  child: const Icon(Icons.list),
                ),
              ),
              Positioned(
                bottom: 16,
                right: 16,
                child: FloatingActionButton(
                  mini: true,
                  heroTag: 'search_btn',
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
