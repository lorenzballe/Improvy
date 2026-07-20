enum TrainingMode { diatonic, chromatic, custom, noteToNumber, ofWhat, pocket }

extension TrainingModeExtension on TrainingMode {
  String get displayName {
    switch (this) {
      case TrainingMode.diatonic: return 'Diatonic';
      case TrainingMode.chromatic: return 'Chromatic';
      case TrainingMode.custom: return 'Custom';
      case TrainingMode.noteToNumber: return 'Note to Number';
      case TrainingMode.ofWhat: return '…Of What?';
      case TrainingMode.pocket: return 'Pocket Mode';
    }
  }

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
