enum TrainingMode { diatonic, chromatic, custom, noteToNumber }

extension TrainingModeExtension on TrainingMode {
  String get displayName {
    switch (this) {
      case TrainingMode.diatonic: return 'Diatonic';
      case TrainingMode.chromatic: return 'Chromatic';
      case TrainingMode.custom: return 'Custom';
      case TrainingMode.noteToNumber: return 'Note to Number';
    }
  }

  String get storageKey {
    switch (this) {
      case TrainingMode.diatonic: return 'diatonic';
      case TrainingMode.chromatic: return 'chromatic';
      case TrainingMode.custom: return 'custom';
      case TrainingMode.noteToNumber: return 'note-to-number';
    }
  }

  static TrainingMode fromString(String s) {
    switch (s) {
      case 'chromatic': return TrainingMode.chromatic;
      case 'custom': return TrainingMode.custom;
      case 'note-to-number': return TrainingMode.noteToNumber;
      default: return TrainingMode.diatonic;
    }
  }
}
