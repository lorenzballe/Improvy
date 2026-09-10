import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n.dart';
import '../providers/app_provider.dart';
import '../services/account_service.dart';
import 'account_sheet.dart';

/// The Account card in Settings. Signed out it is one line and a button;
/// signed in it names the account and offers the two things Apple and
/// Google both require of an app that creates accounts: leaving, and
/// deleting.
class AccountCard extends StatelessWidget {
  const AccountCard({super.key});

  static const _indigo = Color(0xFF4F46E5);

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<AccountUser?>(
        valueListenable: AccountService.instance.user,
        builder: (context, user, _) => user == null ? _signedOut(context) : _signedIn(context, user),
      );

  Widget _signedOut(BuildContext context) {
    final l = context.l10n;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.accountSignedOutTitle,
                  key: const Key('account-signed-out'),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.3)),
              const SizedBox(height: 4),
              Text(l.accountSignedOutSub,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white.withAlpha(120), height: 1.3)),
            ],
          ),
        ),
        const SizedBox(width: 12),
        GestureDetector(
          key: const Key('account-sign-in'),
          onTap: () => AccountSheet.show(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(color: _indigo, borderRadius: BorderRadius.circular(14)),
            child: Text(l.accountSignIn,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2, color: Colors.white)),
          ),
        ),
      ],
    );
  }

  Widget _signedIn(BuildContext context, AccountUser user) {
    final l = context.l10n;
    final icon = user.isApple
        ? Icons.apple_rounded
        : user.isGoogle
            ? Icons.g_mobiledata_rounded
            : Icons.mail_rounded;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(color: Colors.white.withAlpha(15), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.email ?? user.uid,
                      key: const Key('account-email-label'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.2)),
                  const SizedBox(height: 3),
                  Text(l.accountSignedInSub,
                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500, color: Colors.white.withAlpha(120), height: 1.3)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                key: const Key('account-sign-out'),
                onTap: () async {
                  HapticFeedback.lightImpact();
                  await AccountService.instance.signOut();
                },
                child: Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(12),
                    border: Border.all(color: Colors.white.withAlpha(25)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(l.accountSignOut,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2, color: Colors.white)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              key: const Key('account-delete'),
              onTap: () => _confirmDelete(context),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
                child: Text(l.accountDelete,
                    style: TextStyle(
                      fontSize: 11.5, fontWeight: FontWeight.w700, color: const Color(0xFFFB7185).withAlpha(200),
                      decoration: TextDecoration.underline, decorationColor: const Color(0x66FB7185),
                    )),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final l = context.l10n;
    final provider = context.read<AppProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1625),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(l.accountDeleteTitle,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
        content: Text(l.accountDeleteBody,
            style: TextStyle(color: Colors.white.withAlpha(170), fontSize: 13, height: 1.45)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l.cancel, style: TextStyle(color: Colors.white.withAlpha(150), fontWeight: FontWeight.w700)),
          ),
          TextButton(
            key: const Key('account-delete-confirm'),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l.accountDeleteConfirm,
                style: const TextStyle(color: Color(0xFFFB7185), fontWeight: FontWeight.w900, letterSpacing: 1)),
          ),
        ],
      ),
    );
    if (yes != true) return;
    final outcome = await AccountService.instance.deleteAccount();
    if (outcome == AccountOutcome.success) {
      provider.setCodePro(false);
    }
    messenger.showSnackBar(SnackBar(
      content: Text(outcome == AccountOutcome.success ? l.accountDeleted : AccountSheetText.describe(l, outcome)),
      behavior: SnackBarBehavior.floating,
    ));
  }
}
