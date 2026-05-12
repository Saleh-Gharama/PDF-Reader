import 'dart:io';
import 'package:flutter/material.dart';
import 'package:docx_file_viewer/docx_file_viewer.dart';

class DocxViewerWidget extends StatelessWidget {
  final File file;

  const DocxViewerWidget({super.key, required this.file});

  @override
  Widget build(BuildContext context) {
    return DocxView(file: file);
  }
}
