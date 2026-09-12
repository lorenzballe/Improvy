import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:improvy/services/analytics_service.dart';

/// Until an account is handed to PostHog, every person in the dashboard is a
/// random anonymous id — one per device, so the same human shows up as two
/// strangers on two phones and nothing before a sign-in belongs to anybody.
///
/// The call that fixes it lives in one place, and the thing it must be given
/// is the account id rather than the address. These keep both true: the seam
/// is static, so what is checked is the wiring itself.
void main() {
  final account = File('lib/services/account_service.dart').readAsStringSync();

  test('a sign-in identifies with the account id, never the email', () {
    // An address can be changed. Identified by it, every event recorded under
    // the old one would afterwards belong to nobody.
    expect(account, contains('AnalyticsService.instance.identify(u.uid'));
    final call = account.substring(
      account.indexOf('AnalyticsService.instance.identify('),
      account.indexOf('onIdentified?.call();'),
    );
    expect(call, contains("'email': u.email"),
        reason: 'the address still travels, as a property, so a person is findable by it');
    expect(call, isNot(contains('identify(u.email')));
  });

  test('signing out goes back to a NEW anonymous device', () {
    // Without this the next person to pick the phone up inherits the last
    // one's identity and their events land in a stranger's account.
    expect(account, contains('AnalyticsService.instance.resetIdentity()'));
    // The signed-out branch of the auth listener, not the early return in
    // deleteAccount that shares its opening line.
    final listener = account.substring(account.indexOf('Future<void> _onAuth('));
    final signedOut = listener.substring(
      listener.indexOf('if (u == null) {'),
      listener.indexOf('final provider ='),
    );
    expect(signedOut, contains('resetIdentity'));
  });

  test('both calls are no-ops until analytics is switched on', () async {
    // Nothing in analytics may throw: it is called from auth state changes,
    // where an exception would cost the sign-in rather than a chart.
    await AnalyticsService.instance.identify('u1', properties: {'email': null});
    await AnalyticsService.instance.resetIdentity();
  });

  test('the identity is pushed a profile straight away', () {
    // Otherwise the newly identified person is bare until something else
    // happens to change.
    expect(account, contains('onIdentified?.call();'));
    expect(File('lib/main.dart').readAsStringSync(),
        contains('AccountService.instance.onIdentified = provider.syncAnalyticsProfile'));
  });
}
