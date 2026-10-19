// AC-1007: what reaches the device log never carries photo data, file
// paths or names, phone numbers, e-mail addresses, links or tokens, while
// the IDs and times support works from stay readable.
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:porcelain_photo_booth/core/diagnostics/safe_log.dart';

void main() {
  late List<String> lines;
  late void Function(String) previous;

  setUp(() {
    lines = [];
    previous = SafeLog.sink;
    SafeLog.sink = lines.add;
  });
  tearDown(() => SafeLog.sink = previous);

  String clean(String text) => SafeLog.sanitize(text);

  test('phone numbers in any common form', () {
    for (final number in [
      '+1 415 555 0147',
      '(415) 555-0147',
      '415.555.0147',
      '4155550147',
      '+14155550147',
    ]) {
      final line = clean('number $number refused');
      expect(line, 'number <number> refused', reason: number);
    }
  });

  test('e-mail addresses', () {
    expect(
      clean('owner hannah.t+booth@example.co.uk wrote'),
      'owner <email> '
      'wrote',
    );
  });

  test('paths on both platforms and file URIs', () {
    const android =
        '/data/user/0/com.example.porcelain_photo_booth/files/originals/'
        'a.jpg';
    const ipad =
        '/var/mobile/Containers/Data/Application/'
        '1B2C3D4E-0000-4000-8000-123456789ABC/Library/Application Support/x';
    final error = FileSystemException(
      'Cannot open file',
      android,
      const OSError('No space left on device', 28),
    );
    final line = clean(error.toString());
    expect(line, isNot(contains('/data/')));
    expect(line, contains('<path>'));
    expect(line, contains('No space left on device'), reason: 'the cause');
    expect(clean("path = '$ipad'"), isNot(contains('Containers')));
    expect(clean('opened file:///private/var/x/y.tar'), 'opened <path>');
  });

  test('file names guests or operators chose', () {
    expect(
      clean('import of Smith wedding.png failed'),
      isNot(contains('.png')),
    );
    expect(clean('Garden-party.porcelain is damaged'), '<file> is damaged');
    expect(clean('read porcelain-backup-20261114-2341.tar'), 'read <file>');
  });

  test('links keep their host only', () {
    expect(
      clean('GET https://booth.example.com/d/AbCdEf123456?x=1 failed'),
      'GET https://booth.example.com/<…> failed',
    );
  });

  test('photo data, digests and tokens', () {
    expect(
      clean('preview data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQABAAD/2w=='),
      'preview <data>',
    );
    const sha =
        '9f86d081884c7d659a2feaa0c55ad015a3bf4f1b2b0b822cd15d6c15b0f00a08';
    expect(clean('sha $sha'), 'sha <hex>');
    expect(
      clean('token Zx9_qL-2vB7mN4kP8rT1wY6uH3jF5dS0aG2cE7iO9eW'),
      'token <token>',
    );
    expect(
      clean('key dGhpcyBpcyBhIHNlY3JldCBrZXkgd2l0aCBzbGFzaGVzLys='),
      'key <token>',
    );
  });

  test('IDs and times stay readable, even when their digits look like a '
      'phone number', () {
    const ids = [
      '5b023d90-9418-408a-8d2f-0e6c1a7b4c11',
      '00000000-1234-4567-8901-234567890123',
    ];
    for (final id in ids) {
      expect(clean('session $id interrupted'), 'session $id interrupted');
    }
    final random = Random(42);
    String hex(int length) => List.generate(
      length,
      (_) => random.nextInt(16).toRadixString(16),
    ).join();
    for (var i = 0; i < 2000; i++) {
      final id = '${hex(8)}-${hex(4)}-4${hex(3)}-a${hex(3)}-${hex(12)}';
      expect(clean('id $id'), 'id $id');
    }
    expect(
      clean('at 2026-10-19T06:31:54.120Z and 2026-10-19'),
      'at 2026-10-19T06:31:54.120Z and 2026-10-19',
    );
  });

  test('long text is cut', () {
    expect(clean('a ' * 1000).length, 601);
  });

  test('errors are logged by type and cleaned message, never as data', () {
    SafeLog.error(
      const FileSystemException(
        'Cannot write',
        '/data/user/0/app/files/outputs/x.jpg',
      ),
      StackTrace.current,
      context: 'while saving a guest photo',
    );
    expect(
      lines.first,
      startsWith(
        'porcelain: error (while saving a guest '
        'photo): FileSystemException: ',
      ),
    );
    expect(lines.join('\n'), isNot(contains('/data/user')));
  });

  test('events are cleaned too', () {
    SafeLog.event('restore applied', 'from /var/mobile/x/y.tar');
    expect(lines, ['porcelain: restore applied: from <path>']);
  });
}
