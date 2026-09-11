import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/l10n.dart';
import '../services/account_service.dart';
import 'brand_marks.dart';

/// The sign-in sheet, opened from the Account card in Settings — never from
/// onboarding. Nobody has to have an account to play; the account exists so
/// that Pro follows the person, and that is only worth explaining to someone
/// who has something for it to follow.
///
/// Three doors in a fixed order: Apple first on iPhone (Apple asks for it
/// wherever Google is offered, and it is the one most people there have),
/// Google, then email — which opens the form below the buttons rather than
/// a second sheet.
class AccountSheet extends StatefulWidget {
  const AccountSheet({super.key});

  /// Opens the sheet. Resolves true when someone ends up signed in.
  static Future<bool> show(BuildContext context) async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0xBD06030C),
      builder: (_) => const AccountSheet(),
    );
    return ok ?? false;
  }

  @override
  State<AccountSheet> createState() => _AccountSheetState();
}

class _AccountSheetState extends State<AccountSheet> {
  static const _sheet = Color(0xFF1A1625);
  static const _indigo = Color(0xFF4F46E5);

  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _emailOpen = false;
  bool _creating = false;
  bool _busy = false;
  _Door? _pressed;
  String? _message;
  bool _messageIsError = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  bool get _isApplePhone =>
      defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS;

  Future<void> _run(Future<AccountOutcome> Function() go) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    final outcome = await go();
    if (!mounted) return;
    if (outcome == AccountOutcome.success) {
      HapticFeedback.mediumImpact();
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _busy = false;
      _message = outcome == AccountOutcome.cancelled ? null : describe(context.l10n, outcome);
      _messageIsError = true;
    });
  }

  Future<void> _reset() async {
    final email = _email.text.trim();
    if (email.isEmpty) {
      setState(() {
        _message = context.l10n.accountErrorInvalidEmail;
        _messageIsError = true;
      });
      return;
    }
    final outcome = await AccountService.instance.sendPasswordReset(email);
    if (!mounted) return;
    setState(() {
      _message = outcome == AccountOutcome.success
          ? context.l10n.accountResetSent(email)
          : describe(context.l10n, outcome);
      _messageIsError = outcome != AccountOutcome.success;
    });
  }

  static String describe(AppLocalizations l, AccountOutcome o) => AccountSheetText.describe(l, o);

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final media = MediaQuery.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(maxHeight: media.size.height * 0.92),
        decoration: const BoxDecoration(
          color: _sheet,
          border: Border(top: BorderSide(color: Color(0x1AFFFFFF))),
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 14, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(38),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Text(l.accountSheetTitle,
                    style: const TextStyle(
                      fontFamily: 'Outfit', fontSize: 30, fontWeight: FontWeight.w600,
                      letterSpacing: -0.8, height: 1.05, color: Colors.white,
                    )),
                const SizedBox(height: 8),
                Text(l.accountSheetBody,
                    style: TextStyle(fontSize: 12.5, height: 1.5, color: Colors.white.withAlpha(115))),
                const SizedBox(height: 22),
                // Apple first on an iPhone, Google first everywhere else:
                // each platform asks to lead on its own hardware, and Apple
                // additionally requires equal prominence, which is why the
                // two are the same button rather than one loud and one quiet.
                for (final door in _isApplePhone
                    ? [_Door.apple, _Door.google]
                    : [_Door.google, _Door.apple]) ...[
                  _brandButton(l, door),
                  const SizedBox(height: 11),
                ],
                const SizedBox(height: 2),
                _emailLink(l),
                AnimatedSize(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.topCenter,
                  child: _emailOpen ? _emailForm(l) : const SizedBox(width: double.infinity),
                ),
                if (_message != null) ...[
                  const SizedBox(height: 14),
                  Text(
                    _message!,
                    key: const Key('account-message'),
                    style: TextStyle(
                      fontSize: 12.5, height: 1.4, fontWeight: FontWeight.w600,
                      color: _messageIsError ? const Color(0xFFFB7185) : const Color(0xFF34D399),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _emailForm(AppLocalizations l) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 14),
          _field(
            controller: _email,
            hint: l.accountEmailHint,
            keyboardType: TextInputType.emailAddress,
            autofill: const [AutofillHints.email],
          ),
          const SizedBox(height: 10),
          _field(
            controller: _password,
            hint: l.accountPasswordHint,
            obscure: true,
            autofill: [_creating ? AutofillHints.newPassword : AutofillHints.password],
          ),
          const SizedBox(height: 14),
          GestureDetector(
            key: const Key('account-email-go'),
            onTap: () => _run(() => _creating
                ? AccountService.instance.createWithEmail(_email.text, _password.text)
                : AccountService.instance.signInWithEmail(_email.text, _password.text)),
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 160),
              opacity: _busy ? 0.5 : 1,
              child: Container(
                height: 52,
                width: double.infinity,
                decoration: BoxDecoration(color: _indigo, borderRadius: BorderRadius.circular(16)),
                child: Center(
                  child: _busy
                      ? const SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(
                          _creating ? l.accountEmailCreate : l.accountEmailSignIn,
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 1.6, color: Colors.white),
                        ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 6,
            children: [
              _link(
                key: const Key('account-switch'),
                _creating ? l.accountSwitchToSignIn : l.accountSwitchToCreate,
                () => setState(() => _creating = !_creating),
              ),
              if (!_creating) _link(key: const Key('account-forgot'), l.accountForgot, _reset),
            ],
          ),
        ],
      );

  Widget _link(String text, VoidCallback onTap, {Key? key}) => GestureDetector(
        key: key,
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Text(text,
            style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w700,
              color: Colors.white.withAlpha(150), decoration: TextDecoration.underline,
              decorationColor: Colors.white.withAlpha(60),
            )),
      );

  Widget _field({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    bool obscure = false,
    List<String>? autofill,
  }) =>
      Container(
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(10),
          border: Border.all(color: Colors.white.withAlpha(20)),
          borderRadius: BorderRadius.circular(18),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        child: TextField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscure,
          autocorrect: false,
          enableSuggestions: !obscure,
          autofillHints: autofill,
          textCapitalization: TextCapitalization.none,
          style: const TextStyle(fontSize: 14, height: 1.45, color: Colors.white),
          cursorColor: _indigo,
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: hint,
            hintStyle: TextStyle(fontSize: 14, color: Colors.white.withAlpha(77)),
          ),
        ),
      );

  /// The brand buttons, in the light style both companies publish: their
  /// mark at its own colours on white, a black label, and nothing of ours on
  /// top of it. No border and no tint — the two are told apart by their
  /// marks, which is the whole point of using the real ones.
  Widget _brandButton(AppLocalizations l, _Door door) {
    final isApple = door == _Door.apple;
    final down = _pressed == door;
    return GestureDetector(
      key: Key(isApple ? 'account-apple' : 'account-google'),
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _pressed = door),
      onTapCancel: () => setState(() => _pressed = null),
      onTapUp: (_) => setState(() => _pressed = null),
      onTap: _busy
          ? null
          : () => _run(isApple
              ? AccountService.instance.signInWithApple
              : AccountService.instance.signInWithGoogle),
      child: AnimatedScale(
        scale: down ? 0.985 : 1,
        duration: const Duration(milliseconds: 120),
        child: AnimatedOpacity(
          opacity: down ? 0.86 : 1,
          duration: const Duration(milliseconds: 120),
          child: Container(
            height: 57,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isApple)
                  const Icon(Icons.apple, size: 21, color: Colors.black)
                else
                  const GoogleMark(size: 19),
                const SizedBox(width: 9),
                // Flexible, so a longer label in another language shortens
                // rather than running off the end of the button.
                Flexible(
                  child: Text(
                    isApple ? l.accountApple : l.accountGoogle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Email is ours, so it is not dressed up as a third brand: a quiet line
  /// under the two buttons that opens the form in place.
  Widget _emailLink(AppLocalizations l) => GestureDetector(
        key: const Key('account-email'),
        behavior: HitTestBehavior.opaque,
        onTap: _busy ? null : () => setState(() => _emailOpen = !_emailOpen),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(0, 13, 0, 7),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                l.accountEmail,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.1,
                  color: Colors.white.withAlpha(_emailOpen ? 235 : 170),
                ),
              ),
              const SizedBox(width: 4),
              AnimatedRotation(
                turns: _emailOpen ? 0.5 : 0,
                duration: const Duration(milliseconds: 200),
                child: Icon(Icons.keyboard_arrow_down_rounded,
                    size: 19, color: Colors.white.withAlpha(_emailOpen ? 200 : 130)),
              ),
            ],
          ),
        ),
      );

}

/// Which brand button is being drawn.
enum _Door { apple, google }

/// One sentence per outcome. Shared with the Account card's delete flow.
abstract final class AccountSheetText {
  static String describe(AppLocalizations l, AccountOutcome o) => switch (o) {
        AccountOutcome.wrongCredentials => l.accountErrorWrong,
        AccountOutcome.weakPassword => l.accountErrorWeak,
        AccountOutcome.emailInUse => l.accountErrorInUse,
        AccountOutcome.invalidEmail => l.accountErrorInvalidEmail,
        AccountOutcome.offline => l.accountErrorOffline,
        AccountOutcome.needsRecentLogin => l.accountErrorRecent,
        AccountOutcome.notConfigured => l.accountUnavailable,
        AccountOutcome.success || AccountOutcome.cancelled || AccountOutcome.error => l.accountErrorGeneric,
      };
}
