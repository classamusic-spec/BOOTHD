// AC-0602: the booth picks a known built-in camera for the lens it wants,
// falls back to the other built-in lens with a note, and never chooses an
// external camera.
import 'package:flutter_test/flutter_test.dart';
import 'package:porcelain_photo_booth/domain/services/camera_service.dart';

CameraDescriptor _camera(String id, CameraLens lens) =>
    CameraDescriptor(id: id, lens: lens, sensorOrientationDegrees: 90);

void main() {
  final front = _camera('1', CameraLens.front);
  final wide = _camera('0', CameraLens.back);
  final ultraWide = _camera('2', CameraLens.back);
  final usb = _camera('usb', CameraLens.external);

  test("the platform's first camera of the wanted lens is its primary", () {
    final cameras = [wide, ultraWide, front, usb];
    expect(CameraChoice.of(cameras, CameraLens.back).camera, wide);
    expect(CameraChoice.of(cameras, CameraLens.front).camera, front);
    expect(CameraChoice.of(cameras, CameraLens.back).fellBack, isFalse);
  });

  test('a missing lens falls back to the other built-in one, noted', () {
    final rearOnly = CameraChoice.of([usb, wide], CameraLens.front);
    expect(rearOnly.camera, wide);
    expect(rearOnly.fellBack, isTrue);
    final frontOnly = CameraChoice.of([front], CameraLens.back);
    expect(frontOnly.camera, front);
    expect(frontOnly.fellBack, isTrue);
  });

  test('external cameras are never chosen', () {
    expect(CameraChoice.of([usb], CameraLens.front).camera, isNull);
    expect(CameraChoice.of([usb], CameraLens.external).camera, isNull);
    expect(CameraChoice.of([usb, front], CameraLens.external).camera, front);
    expect(CameraChoice.of(const [], CameraLens.back).camera, isNull);
  });

  test('permission codes name the state; granted has none', () {
    expect(CameraPermission.granted.problemCode, isNull);
    expect(
      CameraPermission.values
          .where((p) => p != CameraPermission.granted)
          .map((p) => p.problemCode),
      everyElement(startsWith('CAMERA_PERMISSION_')),
    );
    expect(CameraPermission.notDetermined.canAsk, isTrue);
    expect(CameraPermission.denied.canAsk, isTrue);
    expect(CameraPermission.permanentlyDenied.canAsk, isFalse);
    expect(CameraPermission.restricted.canAsk, isFalse);
  });

  test('every failure has its own CAMERA_ code', () {
    final codes = CameraFailureCode.values.map((c) => c.diagnostic).toList();
    expect(codes.toSet(), hasLength(codes.length));
    expect(codes, everyElement(startsWith('CAMERA_')));
  });
}
