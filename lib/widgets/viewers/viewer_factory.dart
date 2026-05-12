import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pdf_reader/core/constants.dart';
import 'package:pdf_reader/widgets/viewers/pdf_viewer_widget.dart';
import 'package:pdf_reader/widgets/viewers/docx_viewer_widget.dart';
import 'package:pdf_reader/widgets/viewers/office_viewer_widget.dart';

class ViewerFactory {
  static Widget getViewer(File file) {
    final extension = file.path.split('.').last.toLowerCase();

    if (AppConstants.pdfExtensions.contains(extension)) {
      return PdfViewerWidget(file: file);
    } else if (AppConstants.docxExtensions.contains(extension)) {
      return DocxViewerWidget(file: file);
    } else if (AppConstants.officeExtensions.contains(extension)) {
      return OfficeViewerWidget(file: file);
    } else {
      return const Center(
        child: Text('Unsupported file format'),
      );
    }
  }
}
