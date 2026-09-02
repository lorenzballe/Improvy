import '../l10n/generated/app_localizations.dart';

enum TrainingMode { diatonic, chromatic, custom, noteToNumber, ofWhat, pocket }

extension TrainingModeExtension on TrainingMode {
  /// The name shown to the user, in their language.
  String localizedName(AppLocalizations l) => switch (this) {
        TrainingMode.diatonic => l.modeDiatonic,
        TrainingMode.chromatic => l.modeChromatic,
        TrainingMode.custom => l.modeCustom,
        TrainingMode.noteToNumber => l.modeNoteToNumber,
        TrainingMode.ofWhat => l.modeOfWhat,
        TrainingMode.pocket => l.modePocket,
      };

  String get storageKey {
    switch (this) {
      case TrainingMode.diatonic: return 'diatonic';
      case TrainingMode.chromatic: return 'chromatic';
      case TrainingMode.custom: return 'custom';
      case TrainingMode.noteToNumber: return 'note-to-number';
      case TrainingMode.ofWhat: return 'of-what';
      case TrainingMode.pocket: return 'pocket';
    }
  }

  static TrainingMode fromString(String s) {
    switch (s) {
      case 'chromatic': return TrainingMode.chromatic;
      case 'custom': return TrainingMode.custom;
      case 'note-to-number': return TrainingMode.noteToNumber;
      case 'of-what': return TrainingMode.ofWhat;
      case 'pocket': return TrainingMode.pocket;
      default: return TrainingMode.diatonic;
    }
  }
}
