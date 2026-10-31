/// The fixed times of location sharing. `docs/pt-br/compartilhamento.md`
/// explains each one and how they fit together.
library;

/// How often the sharing isolate renews the person's `capturedAt` without a
/// new position (*heartbeat*), so someone standing still stays on the map.
const heartbeat = Duration(minutes: 5);

/// How long a `capturedAt` keeps a person on the map (*validade*): one lost
/// [heartbeat] plus two minutes of slack, whatever the period an administrator chose. A
/// device alive and online never goes past one [heartbeat] without an update;
/// a dead one leaves the map at most [validity] plus [recheck] after its last
/// update. The one freshness threshold of the app.
const validity = Duration(minutes: 12);

/// How often the map re-applies [validity] to the team it already has, with
/// no new document (*recheck*): a dead device never writes again, so only the
/// clock can tell it went quiet.
const recheck = Duration(seconds: 30);
