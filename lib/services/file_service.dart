import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pdf_reader/core/constants.dart';

class FileService {
  Future<File?> pickDocument() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: AppConstants.allSupportedExtensions,
    );

    if (result != null && result.files.single.path != null) {
      return File(result.files.single.path!);
    }
    return null;
  }

  Future<List<File>> discoverFiles() async {
    List<File> files = [];

    // Request permissions
    if (Platform.isAndroid) {
      if (await Permission.storage.request().isGranted ||
          await Permission.manageExternalStorage.request().isGranted) {
        // For simplicity in this environment, we'll check common directories
        // In a real app, you might use a more comprehensive scan or MediaStore
        final directories = [
          Directory('/storage/emulated/0/Download'),
          Directory('/storage/emulated/0/Documents'),
        ];

        for (var dir in directories) {
          if (await dir.exists()) {
            try {
              final entities = await dir.list(recursive: false).toList();
              for (var entity in entities) {
                if (entity is File && _isSupported(entity.path)) {
                  files.add(entity);
                }
              }
            } catch (e) {
              // Handle error silently or log appropriately
            }
          }
        }
      }
    } else if (Platform.isIOS) {
      final dir = await getApplicationDocumentsDirectory();
      final entities = await dir.list(recursive: true).toList();
      for (var entity in entities) {
        if (entity is File && _isSupported(entity.path)) {
          files.add(entity);
        }
      }
    }

    return files;
  }

  bool _isSupported(String path) {
    final ext = getFileExtension(path);
    return AppConstants.allSupportedExtensions.contains(ext);
  }

  String getFileExtension(String path) {
    return path.split('.').last.toLowerCase();
  }
}
