import 'dart:math';

import '../../core/constants.dart';

class PairingPayload {
  const PairingPayload({
    required this.host,
    required this.port,
    required this.code,
  });

  final String host;
  final int port;
  final String code;

  String encode() {
    return Uri(
      scheme: 'buzzit',
      host: 'join',
      queryParameters: <String, String>{
        'host': host,
        'port': port.toString(),
        'code': code,
      },
    ).toString();
  }

  static PairingPayload? tryParse(String value) {
    final uri = Uri.tryParse(value);
    if (uri == null || uri.scheme != 'buzzit' || uri.host != 'join') {
      return null;
    }
    final host = uri.queryParameters['host']?.trim() ?? '';
    final port = int.tryParse(uri.queryParameters['port'] ?? '');
    final code = uri.queryParameters['code'] ?? '';
    if (host.isEmpty ||
        port == null ||
        port < AppConstants.minimumPort ||
        port > AppConstants.maximumPort ||
        !RegExp(r'^\d{6}$').hasMatch(code)) {
      return null;
    }
    return PairingPayload(host: host, port: port, code: code);
  }
}

class PairingService {
  PairingService({Random? random}) : _random = random ?? Random.secure();

  final Random _random;

  String generateCode() {
    final upperBound = pow(10, AppConstants.pairingCodeLength).toInt();
    return _random
        .nextInt(upperBound)
        .toString()
        .padLeft(AppConstants.pairingCodeLength, '0');
  }
}
