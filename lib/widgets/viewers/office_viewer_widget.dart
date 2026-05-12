import 'dart:io';
import 'package:flutter/material.dart';
import 'package:microsoft_viewer/microsoft_viewer.dart';

class OfficeViewerWidget extends StatelessWidget {
  final File file;

  const OfficeViewerWidget({super.key, required this.file});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<int>>(
      future: file.readAsBytes(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error loading file: ${snapshot.error}'));
        } else if (snapshot.hasData) {
          return MicrosoftViewer(snapshot.data!, false);
        } else {
          return const Center(child: Text('No data found'));
        }
      },
    );
  }
}
