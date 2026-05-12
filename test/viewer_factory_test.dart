import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_reader/widgets/viewers/viewer_factory.dart';
import 'package:pdf_reader/widgets/viewers/pdf_viewer_widget.dart';
import 'package:pdf_reader/widgets/viewers/docx_viewer_widget.dart';
import 'package:pdf_reader/widgets/viewers/office_viewer_widget.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('ViewerFactory returns PdfViewerWidget for .pdf files', (WidgetTester tester) async {
    final file = File('test.pdf');
    final widget = ViewerFactory.getViewer(file);
    expect(widget, isA<PdfViewerWidget>());
  });

  testWidgets('ViewerFactory returns DocxViewerWidget for .docx files', (WidgetTester tester) async {
    final file = File('test.docx');
    final widget = ViewerFactory.getViewer(file);
    expect(widget, isA<DocxViewerWidget>());
  });

  testWidgets('ViewerFactory returns OfficeViewerWidget for .pptx files', (WidgetTester tester) async {
    final file = File('test.pptx');
    final widget = ViewerFactory.getViewer(file);
    expect(widget, isA<OfficeViewerWidget>());
  });

  testWidgets('ViewerFactory returns OfficeViewerWidget for .xlsx files', (WidgetTester tester) async {
    final file = File('test.xlsx');
    final widget = ViewerFactory.getViewer(file);
    expect(widget, isA<OfficeViewerWidget>());
  });

  testWidgets('ViewerFactory returns error text for unsupported files', (WidgetTester tester) async {
    final file = File('test.unknown');
    final widget = ViewerFactory.getViewer(file);
    expect(widget, isA<Center>());
  });
}
