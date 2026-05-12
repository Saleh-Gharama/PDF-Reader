class AppConstants {
  static const List<String> pdfExtensions = ['pdf'];
  static const List<String> docxExtensions = ['docx'];
  static const List<String> officeExtensions = ['pptx', 'xlsx'];

  static const List<String> allSupportedExtensions = [
    ...pdfExtensions,
    ...docxExtensions,
    ...officeExtensions,
  ];
}
