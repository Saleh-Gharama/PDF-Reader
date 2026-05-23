import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pdf_reader/widgets/viewers/viewer_factory.dart';
import 'package:pdf_reader/services/preference_service.dart';
import 'package:pdf_reader/services/file_service.dart';
import 'package:pdf_reader/widgets/metadata_dialog.dart';

class ViewerScreen extends StatefulWidget {
  final File file;

  const ViewerScreen({super.key, required this.file});

  @override
  State<ViewerScreen> createState() => _ViewerScreenState();
}

class _ViewerScreenState extends State<ViewerScreen> {
  final PreferenceService _preferenceService = PreferenceService();
  final FileService _fileService = FileService();

  @override
  void initState() {
    super.initState();
    _recordRecent();
  }

  Future<void> _recordRecent() async {
    await _preferenceService.addRecent(widget.file.path);
  }

  void _showMetadata() async {
    final extension = _fileService.getFileExtension(widget.file.path);
    if (extension == 'pdf') {
      final metadata = await _fileService.getPdfMetadata(widget.file);
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => MetadataDialog(metadata: metadata),
        );
      }
    } else {
      // For non-PDF files, show basic file info
      final stat = await widget.file.stat();
      final metadata = {
        'File Name': widget.file.path.split('/').last,
        'File Size': '${(stat.size / 1024).toStringAsFixed(2)} KB',
        'Last Accessed': stat.accessed.toString(),
        'Last Modified': stat.modified.toString(),
        'Extension': extension.toUpperCase(),
      };
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => MetadataDialog(metadata: metadata),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.file.path.split('/').last),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showMetadata,
          ),
        ],
      ),
      body: ViewerFactory.getViewer(widget.file),
    );
  }
}
