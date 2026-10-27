import 'package:flutter/material.dart';

import '../core/design_system/porcelain_theme_data.dart';
import '../core/design_system/theme_profiles.dart';
import '../core/diagnostics/safe_log.dart';
import 'startup_screens.dart';

/// Prepares platform storage before constructing services that depend on
/// it. A failure keeps the UI usable and never exposes exception details.
class PlatformStartup extends StatefulWidget {
  const PlatformStartup({
    super.key,
    required this.prepare,
    required this.start,
  });

  final Future<void> Function() prepare;
  final Widget Function() start;

  @override
  State<PlatformStartup> createState() => _PlatformStartupState();
}

class _PlatformStartupState extends State<PlatformStartup> {
  Object? _failure;
  Widget? _app;

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  Future<void> _prepare() async {
    setState(() => _failure = null);
    try {
      await widget.prepare();
      if (!mounted) return;
      final app = widget.start();
      setState(() => _app = app);
    } on Object catch (error, stack) {
      SafeLog.error(error, stack, context: 'platform startup');
      if (mounted) setState(() => _failure = error);
    }
  }

  @override
  Widget build(BuildContext context) =>
      _app ??
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: porcelainThemeData(PorcelainThemeProfile.porcelainStudio),
        home: _failure == null
            ? const StartingScreen()
            : StartupProblemView(failure: _failure, onRetry: _prepare),
      );
}
