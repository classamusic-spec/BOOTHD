// AC-0305: the route guard. Each access phase reaches only its own routes;
// Booth Mode never leads into the Studio, whatever location is asked for.
import 'package:flutter_test/flutter_test.dart';
import 'package:porcelain_photo_booth/core/access/access_controller.dart';
import 'package:porcelain_photo_booth/core/routing/access_redirect.dart';
import 'package:porcelain_photo_booth/core/routing/route_paths.dart';

String? go(AccessPhase phase, String location) =>
    accessRedirect(phase, Uri.parse(location));

/// Every kind of location an attempt might use.
const attempts = [
  '/',
  '/studio',
  '/studio/events',
  '/studio/events/new',
  '/studio/events/00000000-0000-4000-8000-000000000001',
  '/studio/events/00000000-0000-4000-8000-000000000001/preflight',
  '/studio/templates',
  '/studio/gallery',
  '/studio/settings?section=booth',
  '/studio/diagnostics',
  '/preview/guest-welcome',
  '/dev/components',
  '/dev/camera-spike',
  '/setup',
  '/unlock',
  '/starting',
  '/startup-problem',
  '/no-such-page',
  '//evil.example/studio',
  'https://evil.example/studio/gallery',
];

void main() {
  group('Booth Mode', () {
    test('every location outside the booth leads to the guest welcome', () {
      for (final location in attempts) {
        expect(
          go(AccessPhase.booth, location),
          RoutePaths.booth,
          reason: location,
        );
      }
    });

    test('the booth routes themselves are allowed', () {
      expect(go(AccessPhase.booth, RoutePaths.booth), isNull);
      expect(go(AccessPhase.booth, RoutePaths.boothOperator), isNull);
    });
  });

  group('locked Studio', () {
    test('Studio pages lead to the PIN screen, remembering the page', () {
      final redirect = go(AccessPhase.locked, '/studio/gallery');
      final uri = Uri.parse(redirect!);
      expect(uri.path, RoutePaths.unlock);
      expect(uri.queryParameters['from'], '/studio/gallery');
    });

    test('nothing else is reachable, and foreign hosts are never kept', () {
      for (final location in [
        '/setup',
        '/booth',
        '/booth/operator',
        '/no-such-page',
        'https://evil.example/studio/gallery',
      ]) {
        expect(
          go(AccessPhase.locked, location),
          RoutePaths.unlock,
          reason: location,
        );
      }
      expect(go(AccessPhase.locked, RoutePaths.unlock), isNull);
    });
  });

  group('operator', () {
    test('after unlocking, the remembered Studio page opens', () {
      expect(
        go(AccessPhase.operator, '/unlock?from=%2Fstudio%2Fgallery'),
        '/studio/gallery',
      );
      expect(go(AccessPhase.operator, '/unlock'), RoutePaths.dashboard);
      expect(
        go(
          AccessPhase.operator,
          '/unlock?from=${Uri.encodeComponent('https://evil.example/studio')}',
        ),
        RoutePaths.dashboard,
      );
    });

    test('Studio pages are allowed; setup, PIN and booth pages are not', () {
      for (final location in [
        '/studio',
        '/studio/events/new',
        '/studio/settings?section=booth',
        '/preview/guest-welcome',
        '/no-such-page',
      ]) {
        expect(go(AccessPhase.operator, location), isNull, reason: location);
      }
      for (final location in ['/', '/setup', '/booth', '/booth/operator']) {
        expect(
          go(AccessPhase.operator, location),
          RoutePaths.dashboard,
          reason: location,
        );
      }
    });
  });

  group('setup and startup', () {
    test('before setup only setup is reachable', () {
      for (final location in attempts) {
        expect(
          go(AccessPhase.setup, location),
          location == RoutePaths.setup ? isNull : RoutePaths.setup,
          reason: location,
        );
      }
    });

    test('while starting, the request waits on the splash and is then '
        'judged by the phase that follows', () {
      final waiting = go(AccessPhase.starting, '/studio/events');
      expect(Uri.parse(waiting!).path, RoutePaths.starting);
      expect(go(AccessPhase.starting, waiting), isNull);

      expect(go(AccessPhase.operator, waiting), '/studio/events');
      expect(
        Uri.parse(go(AccessPhase.locked, waiting)!).queryParameters['from'],
        '/studio/events',
      );
      expect(go(AccessPhase.booth, waiting), RoutePaths.booth);
      expect(go(AccessPhase.setup, waiting), RoutePaths.setup);
      expect(go(AccessPhase.startupFailed, waiting), RoutePaths.startupProblem);
    });

    test('a failed startup shows only the problem screen', () {
      for (final location in attempts) {
        expect(
          go(AccessPhase.startupFailed, location),
          location == RoutePaths.startupProblem
              ? isNull
              : RoutePaths.startupProblem,
          reason: location,
        );
      }
    });
  });
}
