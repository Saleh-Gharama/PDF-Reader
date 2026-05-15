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

  @override
  void initState() {
    super.initState();
    _recordRecent();
  }

  Future<void> _recordRecent() async {
    await _preferenceService.addRecent(widget.file.path);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.file.path.split('/').last),
      ),
      body: ViewerFactory.getViewer(widget.file),
    );
  }
}
