import 'dart:convert';

import '../core/constants.dart';

enum MessageType {
  hello('hello'),
  welcome('welcome'),
  buzzAttempt('buzz_attempt'),
  stateSync('state_sync'),
  settingsUpdate('settings_update'),
  ping('ping'),
  pong('pong'),
  error('error');

  const MessageType(this.wireValue);

  final String wireValue;

  static MessageType? fromWireValue(String value) {
    for (final type in values) {
      if (type.wireValue == value) {
        return type;
      }
    }
    return null;
  }
}

class ProtocolMessage {
  ProtocolMessage({
    required this.type,
    this.payload = const <String, Object?>{},
    this.roundId,
    String? messageId,
  }) : messageId = messageId ?? _newMessageId();

  final MessageType type;
  final Map<String, Object?> payload;
  final int? roundId;
  final String messageId;

  String encode() {
    return jsonEncode(<String, Object?>{
      'version': AppConstants.protocolVersion,
      'id': messageId,
      'type': type.wireValue,
      'roundId': roundId,
      'payload': payload,
    });
  }

  factory ProtocolMessage.decode(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      throw const FormatException('Protocol message must be an object.');
    }
    final map = Map<String, Object?>.from(decoded);
    if (map['version'] != AppConstants.protocolVersion) {
      throw const FormatException('Unsupported protocol version.');
    }
    final rawType = map['type'];
    final type = rawType is String ? MessageType.fromWireValue(rawType) : null;
    if (type == null) {
      throw const FormatException('Unknown message type.');
    }
    final messageId = map['id'];
    if (messageId is! String || messageId.trim().isEmpty) {
      throw const FormatException('Protocol message ID must be a string.');
    }
    final roundId = map['roundId'];
    if (roundId != null && (roundId is! int || roundId < 1)) {
      throw const FormatException('Round ID must be a positive integer.');
    }
    final rawPayload = map['payload'];
    if (rawPayload is! Map) {
      throw const FormatException('Protocol payload must be an object.');
    }
    return ProtocolMessage(
      type: type,
      payload: Map<String, Object?>.from(rawPayload),
      roundId: roundId as int?,
      messageId: messageId,
    );
  }

  static String _newMessageId() {
    return DateTime.now().microsecondsSinceEpoch.toRadixString(36);
  }
}
