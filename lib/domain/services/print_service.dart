/// The printer boundary (A-13, P-12): what a printer could do, a request to
/// print a finished photo and where a print job stands.
///
/// Release 1 exports print-ready files and prints nothing: no printer model
/// has been chosen or tested. [UnconfiguredPrintService] is the only
/// adapter. It never queues, submits or reports a print (AC-0806), and no
/// screen offers printing. A future adapter must tell a job handed to the
/// OS ([PrintJobStatus.submitted]) from a print the printer confirmed
/// ([PrintJobStatus.physicalCompleted]), and must ask the operator before
/// retrying a job whose result is unknown.
library;

import 'package:meta/meta.dart';

import '../models/booth_event.dart';
import '../template/page_spec.dart';

/// Where a print job stands (A-13 PrintJob).
enum PrintJobStatus {
  /// No printer is set up; nothing was queued.
  unconfigured,

  /// Accepted by the adapter, not yet sent.
  queued,

  /// Handed to the printer or the OS print system. Not proof of a print.
  submitted,

  /// The printer reported the print finished. Only adapters that can
  /// verify it may report this.
  physicalCompleted,

  /// The printer or OS refused the job.
  failed,

  /// Needs the operator, for example before retrying an unknown result.
  operatorAttention,
}

/// What the configured printer can do (A-13 PrintCapabilities).
@immutable
final class PrintCapabilities {
  const PrintCapabilities({
    required this.configured,
    this.adapterName,
    this.media = const [],
    this.formats = const [],
    this.maxCopies = 0,
    this.reportsPhysicalCompletion = false,
    this.reasonCode,
  });

  /// No printer: nothing can be printed, and nothing pretends to be.
  const PrintCapabilities.unconfigured()
    : configured = false,
      adapterName = null,
      media = const [],
      formats = const [],
      maxCopies = 0,
      reportsPhysicalCompletion = false,
      reasonCode = UnconfiguredPrintService.notConfigured;

  final bool configured;

  /// The adapter's name for the operator, e.g. a printer model. Null when
  /// none is configured.
  final String? adapterName;

  /// Print sizes the printer accepts.
  final List<PageSpec> media;

  /// File formats the adapter accepts.
  final List<OutputFormat> formats;
  final int maxCopies;

  /// Whether the adapter can confirm a finished physical print rather than
  /// only a submitted job.
  final bool reportsPhysicalCompletion;

  /// A `PRINT_*` code saying why printing is unavailable.
  final String? reasonCode;
}

/// A request to print one finished photo (A-13 PrintRequest).
@immutable
final class PrintRequest {
  const PrintRequest({
    required this.outputId,
    required this.page,
    required this.format,
    this.copies = 1,
  });

  /// The recorded finished photo (`SessionOutput.id`).
  final String outputId;

  /// Its print size, from the session's template revision. An adapter
  /// prints at this size or refuses; it never rescales silently.
  final PageSpec page;
  final OutputFormat format;
  final int copies;
}

/// A print job as the adapter reports it.
@immutable
final class PrintJob {
  const PrintJob({required this.status, this.id, this.code});

  /// Null when nothing was queued.
  final String? id;
  final PrintJobStatus status;

  /// A `PRINT_*` diagnostic (A-14).
  final String? code;
}

/// The printer port (A-04 PrintService).
abstract interface class PrintService {
  Future<PrintCapabilities> capabilities();

  /// Asks for [request] to be printed. Returns the job as it stands; never
  /// a status the adapter cannot back up.
  Future<PrintJob> submit(PrintRequest request);

  /// The job [jobId] as it stands now.
  Future<PrintJob> status(String jobId);
}

/// Export-only printing (A-13 `ExportOnlyPrintService`): every answer is
/// "not configured", nothing is queued, and no job ever exists.
final class UnconfiguredPrintService implements PrintService {
  const UnconfiguredPrintService();

  static const notConfigured = 'PRINT_NOT_CONFIGURED';
  static const unknownJob = 'PRINT_UNKNOWN_JOB';

  @override
  Future<PrintCapabilities> capabilities() async =>
      const PrintCapabilities.unconfigured();

  @override
  Future<PrintJob> submit(PrintRequest request) async =>
      const PrintJob(status: PrintJobStatus.unconfigured, code: notConfigured);

  @override
  Future<PrintJob> status(String jobId) async =>
      const PrintJob(status: PrintJobStatus.unconfigured, code: unknownJob);
}
