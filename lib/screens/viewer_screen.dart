import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pdf_reader/widgets/viewers/viewer_factory.dart';

class ViewerScreen extends StatelessWidget {
  final File file;

  const ViewerScreen({super.key, required this.file});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(file.path.split('/').last),
      ),
      body: ViewerFactory.getViewer(file),
    );
  }
}
