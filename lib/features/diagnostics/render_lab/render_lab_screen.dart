import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/service_providers.dart';
import 'render_lab_runner.dart';

/// Dev-only render lab (debug and profile builds only, ADR-0010).
///
/// Runs the renderer's fixture suite on this device: every fixture's pixel
/// checks, the editor workspace, the halo probes and the failure probes,
/// then shows the print outputs. A diagnostic tool, deliberately plain.
class RenderLabScreen extends ConsumerStatefulWidget {
  const RenderLabScreen({super.key});

  @override
  ConsumerState<RenderLabScreen> createState() => _RenderLabScreenState();
}

class _RenderLabScreenState extends ConsumerState<RenderLabScreen> {
  var _running = false;
  RenderLabReport? _report;
  String? _error;

  Future<void> _run() async {
    setState(() {
      _running = true;
      _report = null;
      _error = null;
    });
    try {
      final report = await runRenderLab(ref.read(compositionRendererProvider));
      if (mounted) setState(() => _report = report);
    } on Object catch (error) {
      if (mounted) setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final report = _report;
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Render lab')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton(
              onPressed: _running ? null : _run,
              child: Text(_running ? 'Rendering…' : 'Run the fixture suite'),
            ),
          ),
          if (_error case final error?)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text('The render lab failed: $error'),
            ),
          if (report != null) ...[
            const SizedBox(height: 16),
            Text(
              report.passed ? 'PASS: every check passed' : 'FAIL: see below',
              style: textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                for (final result in report.fixtures)
                  _Output(
                    label:
                        '${result.fixture.id}, '
                        '${result.export.widthPx}x${result.export.heightPx}',
                    png: result.export.bytes,
                  ),
                _Output(
                  label: 'Editor workspace, shows overflow',
                  png: report.workspace.bytes,
                ),
              ],
            ),
            const SizedBox(height: 16),
            for (final line in report.summary())
              Text(
                line,
                style: textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
              ),
          ],
        ],
      ),
    );
  }
}

class _Output extends StatelessWidget {
  const _Output({required this.label, required this.png});

  final String label;
  final Uint8List png;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 220,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 8),
        Image.memory(png, filterQuality: FilterQuality.medium),
      ],
    ),
  );
}
