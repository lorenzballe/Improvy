import 'package:flutter_test/flutter_test.dart';

import 'package:improvy/constants/music_constants.dart';
import 'package:improvy/services/widget_service.dart';
import 'package:improvy/widgets/note_text.dart';

/// The weakest-key widget's URL carries the key the way the widget SHOWS it,
/// which on a Do-Re-Mi phone is "Sol" — a string the app then trained as a
/// key, fell back to C major for, and credited to nobody.
void main() {
  test('a key in the app\'s own spelling comes back as itself', () {
    for (final k in kKeys) {
      expect(WidgetService.keyFromWidgetParam(k), k);
    }
  });

  test('a solfège name resolves to the key it displays', () {
    for (final k in kKeys) {
      final shown = formatNoteForDisplay(k, 'DoReMi');
      expect(WidgetService.keyFromWidgetParam(shown), k, reason: shown);
    }
    expect(WidgetService.keyFromWidgetParam('Sol'), 'G');
    expect(WidgetService.keyFromWidgetParam('Si♭'), 'B♭');
  });

  test('anything else is nothing, not C', () {
    expect(WidgetService.keyFromWidgetParam(null), isNull);
    expect(WidgetService.keyFromWidgetParam(''), isNull);
    expect(WidgetService.keyFromWidgetParam('H'), isNull);
    expect(WidgetService.keyFromWidgetParam('improvy'), isNull);
  });
}
