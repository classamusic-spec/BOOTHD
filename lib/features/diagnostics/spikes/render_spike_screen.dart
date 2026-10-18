import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/service_providers.dart';
import 'render/render_spike_runner.dart';

/// Dev-only M01 render spike (debug and profile builds only).
///
/// Renders FIX-01 offscreen from encoded images on this device and runs
/// every pixel, halo and failure check, showing the print output and the
/// editor workspace. Deliberately plain: this is a feasibility probe.
class RenderSpikeScreen extends ConsumerStatefulWidget {
  const RenderSpikeScreen({super.key});

  @override
  ConsumerState<RenderSpikeScreen> createState() => _RenderSpikeScreenState();
}

class _RenderSpikeScreenState extends ConsumerState<RenderSpikeScreen> {
  var _running = false;
  RenderSpikeReport? _report;
  String? _error;

  Future<void> _run() async {
    setState(() {
      _running = true;
      _report = null;
      _error = null;
    });
    try {
      final report = await runRenderSpike(
        ref.read(compositionRendererProvider),
      );
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
      appBar: AppBar(title: const Text('M01 render spike')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton(
              onPressed: _running ? null : _run,
              child: Text(_running ? 'Rendering…' : 'Run FIX-01 render spike'),
            ),
          ),
          if (_error case final error?)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text('Render spike failed: $error'),
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
                _RenderPreview(
                  label: 'Export, 1200x1800 print output',
                  png: report.export.png,
                ),
                _RenderPreview(
                  label: 'Editor workspace, shows overflow',
                  png: report.workspace.png,
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

class _RenderPreview extends StatelessWidget {
  const _RenderPreview({required this.label, required this.png});

  final String label;
  final Uint8List png;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 280,
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
