// The MMS preview (AC-0909) with the platform decoder and the app's JPEG
// encoder: a JPEG of the whole finished photo, at most 1024 px on its long
// side, under the service's byte budget (and always under the 5 MB the
// spec allows), stepping quality and size down rather than ever going
// over; refused when nothing fits.
import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter_test/flutter_test.dart';
import 'package:porcelain_photo_booth/infrastructure/delivery/jpeg_preview_maker.dart';

import '../support/fake_gallery.dart';

void main() {
  testWidgets('the preview is the whole photo, at most 1024 px, within the '
      'byte budget (AC-0909)', (tester) async {
    await tester.runAsync(() async {
      const maker = JpegPreviewMaker();
      final preview = await maker.make(printStandIn, maxBytes: 600000);
      expect(preview.bytes.sublist(0, 3), [0xFF, 0xD8, 0xFF]);
      expect(preview.bytes.sublist(preview.bytes.length - 2), [0xFF, 0xD9]);
      expect(preview.height, 1024);
      expect(preview.width, closeTo(1024 * 1200 / 1800, 1));
      expect(preview.bytes.length, lessThanOrEqualTo(600000));
      expect(preview.sha256, crypto.sha256.convert(preview.bytes).toString());

      // A tight budget makes it smaller, never larger than allowed.
      final tight = await maker.make(printStandIn, maxBytes: 12000);
      expect(tight.bytes.length, lessThanOrEqualTo(12000));
      expect(tight.height, lessThanOrEqualTo(1024));
      expect(tight.width / tight.height, closeTo(1200 / 1800, 0.01));

      // Nothing fits: refused, not sent over the limit.
      await expectLater(
        maker.make(printStandIn, maxBytes: 300),
        throwsA(isA<StateError>()),
      );
    });
  });
}
