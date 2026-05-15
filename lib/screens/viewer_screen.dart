import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pdf_reader/widgets/viewers/viewer_factory.dart';
import 'package:pdf_reader/services/preference_service.dart';

class ViewerScreen extends StatefulWidget {
  final File file;

  const ViewerScreen({super.key, required this.file});

  @override
  State<ViewerScreen> createState() => _ViewerScreenState();
}

class _ViewerScreenState extends State<ViewerScreen> {
  final PreferenceService _preferenceService = PreferenceService();
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _preferenceService.addToRecents(widget.file.path);
    final isFav = await _preferenceService.isFavorite(widget.file.path);
    if (mounted) {
      setState(() {
        _isFavorite = isFav;
      });
    }
  }

  Future<void> _toggleFavorite() async {
    await _preferenceService.toggleFavorite(widget.file.path);
    setState(() {
      _isFavorite = !_isFavorite;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.file.path.split('/').last),
        actions: [
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: _isFavorite ? Colors.red : null,
            ),
            onPressed: _toggleFavorite,
          ),
        ],
      ),
      body: ViewerFactory.getViewer(widget.file),
    );
  }
}
