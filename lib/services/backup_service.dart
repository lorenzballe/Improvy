import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'analytics_service.dart';
import 'storage_service.dart';

/// Progress and settings in, progress and settings out, as one file.
///
/// The device backup already carries the preferences to a new phone restored
/// from it. What it does not cover is the two things people actually do:
/// uninstall and reinstall, and move between iPhone and Android. For someone
/// who paid for a lifetime licence and lost six months of keys, "it was in
/// your iCloud backup" is not an answer. This is.
class BackupService {
  BackupService._();
  static final BackupService instance = BackupService._();

  static bool get available => !kIsWeb;

  /// Writes the export to a file and hands it to the share sheet, where it can
  /// go to Files, Drive, Mail or another phone. Returns false if the share
  /// could not be started.
  Future<bool> export(StorageService storage) async {
    if (!available) return false;
    try {
      final dir = await getTemporaryDirectory();
      final stamp = DateTime.now().toIso8601String().substring(0, 10);
      final file = File('${dir.path}/improvy-backup-$stamp.json');
      await file.writeAsString(storage.exportJson());
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/json')],
        subject: 'Improvy backup $stamp',
      );
      AnalyticsService.instance.capture(Ev.backupExported);
      return true;
    } catch (e) {
      AnalyticsService.instance.error(Ev.backupFailed, e, {'step': 'export'});
      return false;
    }
  }

  /// Lets the user pick a backup and restores it. Returns null on success,
  /// a short reason on failure, and the empty string if they cancelled.
  Future<String?> import(StorageService storage) async {
    if (!available) return 'Not available on the web';
    try {
      final picked = await FilePicker.platform.pickFiles(
        type: FileType.any,
        withData: true,
      );
      if (picked == null || picked.files.isEmpty) return '';
      final f = picked.files.first;
      final bytes = f.bytes ?? (f.path != null ? await File(f.path!).readAsBytes() : null);
      if (bytes == null) return 'Could not read that file';
      await storage.importJson(String.fromCharCodes(bytes));
      AnalyticsService.instance.capture(Ev.backupImported);
      return null;
    } on FormatException catch (e) {
      return 'That is ${e.message}';
    } catch (e) {
      AnalyticsService.instance.error(Ev.backupFailed, e, {'step': 'import'});
      return 'Something went wrong restoring the file';
    }
  }
}
