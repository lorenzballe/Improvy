import 'package:flutter/material.dart';
import '../l10n/l10n.dart';
import 'package:flutter/services.dart';

import '../services/analytics_service.dart';

/// What the message is about. Three buckets, because a list of free text with
/// no bucket is unreadable after twenty entries — and because "it's broken"
/// and "you should add" want completely different reactions from me.
enum FeedbackKind {
  bug('bug', Icons.bug_report_rounded, Color(0xFFF43F5E)),
  idea('idea', Icons.lightbulb_rounded, Color(0xFFFBBF24)),
  other('other', Icons.chat_bubble_rounded, Color(0xFF6366F1));

  const FeedbackKind(this.id, this.icon, this.color);
  final String id;
  final IconData icon;
  final Color color;

  String label(AppLocalizations l) => switch (this) {
        FeedbackKind.bug => l.feedbackKindBug,
        FeedbackKind.idea => l.feedbackKindIdea,
        FeedbackKind.other => l.feedbackKindOther,
      };
}

/// The in-app feedback sheet.
///
/// Deliberately NOT a mailto: link. A mail composer asks the user to own the
/// message — to have a mail app set up, to see their own address on it, to
/// press send in a different app — and most people back out at that point.
/// This is a box and a button, and the message rides out on the analytics
/// channel that is already running, so nothing new has to be configured and
/// nothing can fail to open.
///
/// What arrives with it, for free: every super and person property already on
/// the user (version, platform, is_pro, level, locale). So a bug report says
/// which build it came from without ever asking.
class FeedbackSheet extends StatefulWidget {
  /// Where the sheet was opened from, recorded on the event.
  final String source;

  const FeedbackSheet({super.key, required this.source});

  /// Opens the sheet. Returns true if a message was actually sent.
  static Future<bool> show(BuildContext context, {String source = 'settings'}) async {
    AnalyticsService.instance.capture(Ev.feedbackOpened, {'source': source});
    final sent = await showModalBottomSheet<bool>(
      context: context,
      // The keyboard must push the sheet, not cover the field being typed in.
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0xBD06030C),
      builder: (_) => FeedbackSheet(source: source),
    );
    return sent ?? false;
  }

  @override
  State<FeedbackSheet> createState() => _FeedbackSheetState();
}

class _FeedbackSheetState extends State<FeedbackSheet> {
  static const _sheet = Color(0xFF1A1625);
  static const _indigo = Color(0xFF4F46E5);

  /// Long enough for a paragraph, short enough that no single event can carry
  /// a novel into the analytics pipeline.
  static const _maxChars = 1200;

  /// Below this it is a slip of the thumb, not a message.
  static const _minChars = 4;

  final _text = TextEditingController();
  final _email = TextEditingController();
  FeedbackKind _kind = FeedbackKind.idea;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    // Rebuilds the send button as the box fills, so it lights up the moment
    // there is something worth sending.
    _text.addListener(_onChanged);
  }

  void _onChanged() => setState(() {});

  @override
  void dispose() {
    _text.removeListener(_onChanged);
    _text.dispose();
    _email.dispose();
    super.dispose();
  }

  bool get _canSend => _text.text.trim().length >= _minChars && !_sending;

  Future<void> _send() async {
    if (!_canSend) return;
    setState(() => _sending = true);
    final body = _text.text.trim();
    final reply = _email.text.trim();
    AnalyticsService.instance.capture(Ev.feedbackSubmitted, {
      'kind': _kind.id,
      'message': body,
      'length': body.length,
      'has_email': reply.isNotEmpty,
      // Only ever what the user typed into the reply box themselves. Nothing
      // is read off the device.
      if (reply.isNotEmpty) 'email': reply,
      'source': widget.source,
    });
    HapticFeedback.mediumImpact();
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return Padding(
      // The keyboard inset, so the sheet rides above it.
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(maxHeight: media.size.height * 0.9),
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
                Text(
                  context.l10n.feedbackTitle,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 30,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.8,
                    height: 1.05,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  context.l10n.feedbackBody,
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.5,
                    color: Colors.white.withAlpha(115),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    for (final k in FeedbackKind.values) ...[
                      Expanded(child: _chip(k)),
                      if (k != FeedbackKind.values.last) const SizedBox(width: 8),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
                _field(
                  controller: _text,
                  hint: _kind == FeedbackKind.bug
                      ? context.l10n.feedbackHintBug
                      : context.l10n.feedbackHint,
                  maxLines: 5,
                  maxLength: _maxChars,
                  autofocus: true,
                ),
                const SizedBox(height: 10),
                _field(
                  controller: _email,
                  hint: context.l10n.feedbackEmail,
                  maxLines: 1,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 18),
                _sendButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _chip(FeedbackKind k) {
    final on = _kind == k;
    return GestureDetector(
      onTap: () => setState(() => _kind = k),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          color: on ? k.color.withAlpha(38) : Colors.white.withAlpha(10),
          border: Border.all(
            color: on ? k.color.withAlpha(128) : Colors.white.withAlpha(20),
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(k.icon, size: 18, color: on ? k.color : Colors.white.withAlpha(102)),
            const SizedBox(height: 6),
            // Scaled rather than wrapped: three labels of different lengths
            // across a phone's width, and the shortest must not set the size
            // of the tallest chip.
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                k.label(context.l10n),
                maxLines: 1,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: on ? Colors.white : Colors.white.withAlpha(115),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String hint,
    required int maxLines,
    int? maxLength,
    bool autofocus = false,
    TextInputType? keyboardType,
  }) =>
      Container(
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(10),
          border: Border.all(color: Colors.white.withAlpha(20)),
          borderRadius: BorderRadius.circular(18),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: TextField(
          controller: controller,
          autofocus: autofocus,
          maxLines: maxLines,
          minLines: maxLines > 1 ? 3 : 1,
          maxLength: maxLength,
          keyboardType: keyboardType ?? TextInputType.multiline,
          textCapitalization: TextCapitalization.sentences,
          style: const TextStyle(fontSize: 14, height: 1.45, color: Colors.white),
          cursorColor: _indigo,
          decoration: InputDecoration(
            border: InputBorder.none,
            // The counter is noise until the limit is in sight.
            counterStyle: TextStyle(
              fontSize: 10,
              color: Colors.white.withAlpha(
                  controller.text.length > _maxChars - 200 ? 115 : 0),
            ),
            hintText: hint,
            hintStyle: TextStyle(fontSize: 14, color: Colors.white.withAlpha(77)),
          ),
        ),
      );

  Widget _sendButton() => GestureDetector(
        onTap: _send,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 160),
          opacity: _canSend ? 1 : 0.35,
          child: Container(
            height: 54,
            width: double.infinity,
            decoration: BoxDecoration(
              color: _indigo,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                context.l10n.feedbackSend,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.6,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      );
}
