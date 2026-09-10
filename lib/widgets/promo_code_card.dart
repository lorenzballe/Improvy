import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n.dart';
import '../providers/app_provider.dart';
import '../services/account_service.dart';
import '../services/promo_code_service.dart';
import 'account_sheet.dart';

/// The Promotional Codes card in Settings: a field, a button, one sentence
/// back. A code is spent on the signed-in account, so a signed-out person
/// who taps Redeem is sent to sign in first rather than told no.
class PromoCodeCard extends StatefulWidget {
  const PromoCodeCard({super.key});

  @override
  State<PromoCodeCard> createState() => _PromoCodeCardState();
}

class _PromoCodeCardState extends State<PromoCodeCard> {
  static const _gold = Color(0xFFFBBF24);
  static const _indigo = Color(0xFF4F46E5);

  final _code = TextEditingController();
  bool _busy = false;
  String? _message;
  bool _messageIsError = true;

  @override
  void initState() {
    super.initState();
    _code.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  bool get _canRedeem => !_busy && PromoCode.normalise(_code.text) != null;

  Future<void> _redeem() async {
    if (!_canRedeem) return;
    final l = context.l10n;
    final provider = context.read<AppProvider>();
    var user = AccountService.instance.user.value;
    if (user == null) {
      setState(() {
        _message = l.promoSignInFirst;
        _messageIsError = true;
      });
      final ok = await AccountSheet.show(context);
      if (!ok || !mounted) return;
      user = AccountService.instance.user.value;
      if (user == null) return;
      // Signing in may have found a code already on the account.
      if (provider.promoCode != null) {
        setState(() => _message = null);
        return;
      }
    }
    setState(() {
      _busy = true;
      _message = null;
    });
    final outcome = await PromoCodeService.instance.redeem(_code.text, uid: user.uid);
    if (!mounted) return;
    if (outcome == PromoOutcome.success) {
      HapticFeedback.heavyImpact();
      provider.setCodePro(true, PromoCode.normalise(_code.text));
      _code.clear();
    }
    setState(() {
      _busy = false;
      _message = describe(l, outcome);
      _messageIsError = outcome != PromoOutcome.success;
    });
  }

  static String describe(AppLocalizations l, PromoOutcome o) => switch (o) {
        PromoOutcome.success => l.promoSuccess,
        PromoOutcome.notSignedIn => l.promoSignInFirst,
        PromoOutcome.alreadyRedeemed => l.promoAlready,
        PromoOutcome.malformed => l.promoMalformed,
        PromoOutcome.unknown => l.promoUnknown,
        PromoOutcome.inactive => l.promoInactive,
        PromoOutcome.exhausted => l.promoExhausted,
        PromoOutcome.expired => l.promoExpired,
        PromoOutcome.offline => l.promoOffline,
        PromoOutcome.notConfigured => l.accountUnavailable,
        PromoOutcome.error => l.promoError,
      };

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final redeemed = context.select<AppProvider, String?>((p) => p.promoCode);
    if (redeemed != null) {
      return Row(
        children: [
          const Icon(Icons.verified_rounded, color: _gold, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              l.promoRedeemedWith(redeemed),
              key: const Key('promo-redeemed'),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white, height: 1.35),
            ),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l.promoTitle,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.3)),
        const SizedBox(height: 4),
        Text(l.promoBody,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white.withAlpha(120), height: 1.3)),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: Container(
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(10),
                  border: Border.all(color: Colors.white.withAlpha(20)),
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                alignment: Alignment.centerLeft,
                child: TextField(
                  key: const Key('promo-field'),
                  controller: _code,
                  enabled: !_busy,
                  textCapitalization: TextCapitalization.characters,
                  autocorrect: false,
                  enableSuggestions: false,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9\-]')),
                    LengthLimitingTextInputFormatter(32),
                  ],
                  onSubmitted: (_) => _redeem(),
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 2, color: Colors.white),
                  cursorColor: _gold,
                  decoration: InputDecoration(
                    isCollapsed: true,
                    border: InputBorder.none,
                    hintText: l.promoHint,
                    hintStyle: TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.5, color: Colors.white.withAlpha(70)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              key: const Key('promo-redeem'),
              onTap: _redeem,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 160),
                opacity: _canRedeem ? 1 : 0.4,
                child: Container(
                  height: 46,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  decoration: BoxDecoration(color: _indigo, borderRadius: BorderRadius.circular(14)),
                  child: Center(
                    child: _busy
                        ? const SizedBox(
                            width: 16, height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(l.promoRedeem,
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.2, color: Colors.white)),
                  ),
                ),
              ),
            ),
          ],
        ),
        if (_message != null) ...[
          const SizedBox(height: 12),
          Text(
            _message!,
            key: const Key('promo-message'),
            style: TextStyle(
              fontSize: 12, height: 1.4, fontWeight: FontWeight.w600,
              color: _messageIsError ? const Color(0xFFFB7185) : const Color(0xFF34D399),
            ),
          ),
        ],
      ],
    );
  }
}
