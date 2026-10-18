// Runs only on a device, emulator or simulator:
//   flutter test integration_test -d <device-id>
// A pass here proves the app launches on that target and shows the Studio
// dashboard. It is not camera, export or certification evidence
// (TEST_AND_DEVICE_PLAN T-03).
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:porcelain_photo_booth/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('cold start shows the Studio dashboard', (tester) async {
    app.main();
    await tester.pumpAndSettle();

    expect(find.text('Set up your first event'), findsOneWidget);
    expect(find.text('Start Booth'), findsOneWidget);
  });
}
