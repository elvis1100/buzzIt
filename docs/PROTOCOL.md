# BuzzIt protocol

BuzzIt uses JSON messages over a local WebSocket at `/ws`. The current protocol
version is `1`. Every message includes a unique `id`, a `type`, an optional
`roundId`, and a `payload` object.

```json
{
  "version": 1,
  "id": "message-id",
  "type": "buzz_attempt",
  "roundId": 12,
  "payload": { "team": "a" }
}
```

## Connection lifecycle

1. The Android client connects to `ws://HOST:PORT/ws`.
2. It sends `hello` with the six-digit pairing code.
3. The host validates the code and enforces the one-client limit.
4. The host sends `welcome` with the authoritative match configuration and
   current round state.
5. Subsequent state changes are delivered through `state_sync`.

## Message types

| Type | Sender | Purpose |
| --- | --- | --- |
| `hello` | Player | Authenticate the initial socket with the pairing code. |
| `welcome` | Host | Confirm pairing and provide the complete current state. |
| `buzz_attempt` | Player | Request a winner for the specified active round. |
| `state_sync` | Host | Broadcast winner, reset, and match configuration changes. |
| `settings_update` | Player | Request team name or color changes. |
| `ping` / `pong` | Either | Application-level liveness support. |
| `error` | Either | Report invalid messages, pairing, or client-limit errors. |

The host accepts only the first valid `buzz_attempt` whose `roundId` matches a
ready round. Later or stale attempts receive the existing authoritative state.
Resetting increments `roundId`, preventing delayed network packets from winning
a future round.
