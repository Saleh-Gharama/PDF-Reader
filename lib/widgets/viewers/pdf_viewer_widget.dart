import 'dart:io';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class PdfViewerWidget extends StatelessWidget {
  final File file;

  const PdfViewerWidget({super.key, required this.file});

  @override
  Widget build(BuildContext context) {
    return SfPdfViewer.file(file);
  }
}
