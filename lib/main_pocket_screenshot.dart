// Dev-only entrypoint: Pocket Mode setup → runtime, for preview/screenshots.
// Not referenced by any production build —
// `flutter build web --target lib/main_pocket_screenshot.dart`.
import 'package:flutter/material.dart';
import 'screens/setup_screen.dart';
import 'screens/pocket_mode_screen.dart';

void main() => runApp(const MaterialApp(debugShowCheckedModeBanner: false, home: _Host()));

class _Host extends StatefulWidget {
  const _Host();
  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  PocketConfig? _config;
  @override
  Widget build(BuildContext context) {
    if (_config != null) {
      return PocketModeScreen(config: _config!, onExit: () => setState(() => _config = null));
    }
    return PocketModeSetup(
      initialKey: 'C',
      onCancel: () {},
      onStart: (c) => setState(() => _config = c),
    );
  }
}
