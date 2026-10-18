// Runs only on a device, emulator or simulator:
//   flutter test integration_test -d <device-id>
// A pass here proves the app launches on that target. It is not camera,
// export or certification evidence (TEST_AND_DEVICE_PLAN T-03).
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:porcelain_photo_booth/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('cold start shows the M00 baseline screen', (tester) async {
    app.main();
    await tester.pumpAndSettle();

    expect(find.text('Porcelain Photo Booth'), findsOneWidget);
    expect(find.text('Engineering baseline · M00'), findsOneWidget);
  });
}
