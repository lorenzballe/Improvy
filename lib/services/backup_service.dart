import 'dart:io';

import 'package:file_selector/file_selector.dart';
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
  ///
  /// Uses file_selector, not file_picker: the latter's iOS plugin links
  /// UIImagePickerController and PHPickerViewController whether or not media
  /// is ever asked for, and Apple's static scan rejects the binary for the
  /// camera and photo-library purpose strings that implies — for an app that
  /// opens one JSON file. file_selector is UIDocumentPickerViewController and
  /// nothing else, which is exactly the capability this needs.
  Future<String?> import(StorageService storage) async {
    if (!available) return 'Not available on the web';
    try {
      const type = XTypeGroup(
        label: 'Improvy backup',
        extensions: ['json'],
        uniformTypeIdentifiers: ['public.json', 'public.text'],
        mimeTypes: ['application/json', 'text/plain'],
      );
      final file = await openFile(acceptedTypeGroups: const [type]);
      if (file == null) return '';
      await storage.importJson(await file.readAsString());
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
