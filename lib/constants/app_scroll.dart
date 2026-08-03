import 'package:flutter/widgets.dart';

/// The scroll feel, in one place.
///
/// Every scrollable surface in the app uses this. Left to the platform default
/// the app rubber-bands on iOS and sits dead still on Android, and — worse —
/// screens drift apart from each other as some get an explicit physics and
/// others don't: Settings bounced while Training and Stats did not, which is
/// exactly the kind of inconsistency you feel without being able to name it.
///
/// [AlwaysScrollableScrollPhysics] as the parent means a short page still
/// gives, instead of feeling locked when its content happens to fit.
const ScrollPhysics kAppScrollPhysics =
    BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());
