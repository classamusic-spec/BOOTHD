import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

import '../../domain/services/delivery_api.dart';
import '../delivery/http_delivery_api.dart';

/// [DeliveryHttpSend] with the browser's `fetch` (ADR-0018). The service
/// must allow this site's origin (CORS); browsers do not let a page set
/// its own User-Agent, so that header is left out. Redirects are not
/// followed: a redirected answer reads as status 0 and is refused.
Future<DeliveryHttpResponse> fetchDeliverySend(
  String method,
  Uri url,
  Map<String, String> headers,
  Uint8List? body,
  Duration timeout,
) async {
  final abort = web.AbortController();
  final timer = Timer(timeout, abort.abort);
  final requestHeaders = web.Headers();
  headers.forEach((name, value) {
    if (name.toLowerCase() != 'user-agent') requestHeaders.set(name, value);
  });
  try {
    final response = await web.window
        .fetch(
          url.toString().toJS,
          web.RequestInit(
            method: method,
            headers: requestHeaders,
            body: body?.toJS,
            redirect: 'manual',
            credentials: 'omit',
            cache: 'no-store',
            signal: abort.signal,
          ),
        )
        .toDart;
    final buffer = await response.arrayBuffer().toDart;
    final retryAfter = response.headers.get('retry-after');
    return (
      status: response.status,
      headers: {'retry-after': ?retryAfter},
      body: buffer.toDart.asUint8List(),
    );
  } on Object {
    // A timeout aborts the request; anything else is the network or CORS,
    // which the page cannot tell apart.
    throw DeliveryApiException(
      DeliveryFailureKind.transient,
      abort.signal.aborted ? 'TIMEOUT' : 'OFFLINE',
    );
  } finally {
    timer.cancel();
  }
}
