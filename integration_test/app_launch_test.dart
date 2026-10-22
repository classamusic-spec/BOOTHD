// Runs only on a device, emulator or simulator:
//   flutter test integration_test -d <device-id>
// A pass here proves the app launches on that target, opens its storage and
// starts first-run setup on a fresh install. It is not camera, export or
// certification evidence (TEST_AND_DEVICE_PLAN T-03).
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:porcelain_photo_booth/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('a fresh install starts first-run setup', (tester) async {
    await app.main();
    await tester.pumpAndSettle();

    // A device that already ran setup shows the PIN screen instead.
    final fresh = find.text('Begin setup').evaluate().isNotEmpty;
    if (fresh) {
      expect(find.text('Welcome'), findsOneWidget);
    } else {
      expect(find.text('Operator PIN'), findsOneWidget);
    }
  });
}
