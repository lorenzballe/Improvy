enum TrainingMode { diatonic, chromatic, custom, noteToNumber, ofWhat }

extension TrainingModeExtension on TrainingMode {
  String get displayName {
    switch (this) {
      case TrainingMode.diatonic: return 'Diatonic';
      case TrainingMode.chromatic: return 'Chromatic';
      case TrainingMode.custom: return 'Custom';
      case TrainingMode.noteToNumber: return 'Note to Number';
      case TrainingMode.ofWhat: return '…Of What?';
    }
  }

  String get storageKey {
    switch (this) {
      case TrainingMode.diatonic: return 'diatonic';
      case TrainingMode.chromatic: return 'chromatic';
      case TrainingMode.custom: return 'custom';
      case TrainingMode.noteToNumber: return 'note-to-number';
      case TrainingMode.ofWhat: return 'of-what';
    }
  }

  static TrainingMode fromString(String s) {
    switch (s) {
      case 'chromatic': return TrainingMode.chromatic;
      case 'custom': return TrainingMode.custom;
      case 'note-to-number': return TrainingMode.noteToNumber;
      case 'of-what': return TrainingMode.ofWhat;
      default: return TrainingMode.diatonic;
    }
  }
}
