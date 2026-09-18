import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import '../database/db_helper.dart';

class BackupService {
  static Future<String?> exportToJson() async {
    try {
      final data = await DBHelper.instance.exportAllData();
      final jsonString = const JsonEncoder.withIndent('  ').convert(data);

      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.').first;
      final fileName = 'cabra_bean_backup_$timestamp.json';
      final file = File('${tempDir.path}/$fileName');

      await file.writeAsString(jsonString, flush: true);

      // Share file
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/json')],
        subject: 'Cabra Bean Database Backup - $timestamp',
        text: 'نسخة احتياطية لقاعدة بيانات كابرا بين - $fileName',
      );

      return file.path;
    } catch (e) {
      return null;
    }
  }

  static Future<bool> importFromJson() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.single.path == null) {
        return false;
      }

      final file = File(result.files.single.path!);
      final content = await file.readAsString();
      final Map<String, dynamic> data = jsonDecode(content);

      final success = await DBHelper.instance.importData(data);
      return success;
    } catch (e) {
      return false;
    }
  }
}
