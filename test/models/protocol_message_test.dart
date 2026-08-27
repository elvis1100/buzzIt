import 'package:buzz_it/models/protocol_message.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('round-trips a versioned protocol message', () {
    final original = ProtocolMessage(
      type: MessageType.buzzAttempt,
      roundId: 42,
      messageId: 'test-message',
      payload: const <String, Object?>{'team': 'a'},
    );

    final decoded = ProtocolMessage.decode(original.encode());

    expect(decoded.type, MessageType.buzzAttempt);
    expect(decoded.roundId, 42);
    expect(decoded.messageId, 'test-message');
    expect(decoded.payload['team'], 'a');
  });

  test('rejects unsupported protocol versions', () {
    expect(
      () => ProtocolMessage.decode(
        '{"version":999,"id":"x","type":"ping","payload":{}}',
      ),
      throwsFormatException,
    );
  });

  test('rejects malformed IDs, round IDs, and payloads', () {
    expect(
      () => ProtocolMessage.decode(
        '{"version":1,"id":null,"type":"ping","payload":{}}',
      ),
      throwsFormatException,
    );
    expect(
      () => ProtocolMessage.decode(
        '{"version":1,"id":"x","type":"ping","roundId":"1","payload":{}}',
      ),
      throwsFormatException,
    );
    expect(
      () => ProtocolMessage.decode(
        '{"version":1,"id":"x","type":"ping","payload":[]}',
      ),
      throwsFormatException,
    );
  });
}
