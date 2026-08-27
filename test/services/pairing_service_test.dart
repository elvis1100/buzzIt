import 'dart:math';

import 'package:buzz_it/services/pairing/pairing_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('encodes and parses a pairing QR payload', () {
    const original = PairingPayload(
      host: '192.168.1.25',
      port: 45821,
      code: '004219',
    );

    final decoded = PairingPayload.tryParse(original.encode());

    expect(decoded, isNotNull);
    expect(decoded!.host, original.host);
    expect(decoded.port, original.port);
    expect(decoded.code, original.code);
  });

  test('rejects unrelated and incomplete QR values', () {
    expect(PairingPayload.tryParse('https://example.com'), isNull);
    expect(
      PairingPayload.tryParse('buzzit://join?host=192.168.1.2&port=1&code=12'),
      isNull,
    );
  });

  test('always generates a six-digit numeric code', () {
    final service = PairingService(random: Random(7));

    final code = service.generateCode();

    expect(code, matches(RegExp(r'^\d{6}$')));
  });
}
