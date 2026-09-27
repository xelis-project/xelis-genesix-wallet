# XSWD in Genesix

XSWD (XELIS Secure WebSocket DApp) lets an external application request access
and wallet operations through Genesix. This document defines the architecture,
consent rules, and supported capabilities. Read it before changing XSWD
connections, permissions, or transaction review.

## Architecture

Genesix supports local connections through the wallet's XSWD server and remote
connections through a relayer, established using a QR code, pasted link, or deep
link. Both follow the same consent and validation rules.

Responsibilities are split between three components:

- `xelis_wallet_flutter` (XWF) owns transport, live sessions, callbacks, and the
  native wallet boundary.
- `xelis_dart_sdk` defines the RPC and event catalogue and their typed models.
- Genesix decides which operations are supported, validates and presents
  requests, and collects the user's decision.

Applications and their requests are untrusted. Malformed, unknown, unsupported,
or incompletely reviewable operations are rejected.
Sensitive connection and request payloads must stay out of logs, analytics,
crash reports, navigation state, and support messages.

## Connections

Accepting a connection allows an application to communicate with Genesix; it
neither grants its requested permissions nor authorizes a transaction.

Each connection has its own identity and permission rules. An application ID
is descriptive metadata, not authority to act on a session. Genesix uses the
live session reference supplied by XWF, so simultaneous local and relayed
connections remain independent even if they share an application ID. Restoring
a screen or reconnecting cannot restore the authority of an earlier session.

Every approval belongs to its originating request, connection, and wallet.
Closing that connection cancels its pending approval and prevents new requests;
a cancellation from another connection must not interfere. Closing or replacing
the wallet invalidates its pending approvals. Delayed actions must never apply
to a newer request or session.

A pending decision expires after three minutes. Reopening its review does not
restart the deadline, and expiration grants no permission. A notification is
only an entry point to the decision; it is not proof that an operation or
connection shutdown has completed. Peer disconnection detection may be delayed
while a permission request is awaiting a decision.

## Permissions

Permission rules are **Allowed**, **Ask every time**, or
**Blocked**. A decision defaults to the current request only. For eligible
methods, the user may instead remember a rule for the current connection.
One-time approval or refusal does not change that rule, and reconnecting does
not retain it. Unsupported methods remain unavailable even under **Ask**.

Genesix explains the operation and its scope before consent, including access
to private wallet activity or the connected node's address. Editing a rule
changes that method alone, without replacing other permission choices.

An application may request several permissions in advance through
`xswd.prefetch_permissions`. Genesix grants only the eligible methods selected
by the user; omitted methods keep their existing rules. A blocked method needs
explicit reselection. Continuing without new permissions preserves the
connection and grants nothing. A batch cannot preauthorize transactions or
other operations that require dedicated review.

`subscribe` and `unsubscribe` are separate permissions. Each actual call names
one wallet event in `params.notify`. A one-time decision covers that call;
connection-wide approval covers future calls for any supported event, including
private wallet activity. Preauthorizing either method does not itself start or
stop subscriptions, and permission rules are not a list of active subscriptions.

Recent choices are temporary, connection-scoped records of consent, not proof
that the requested operations ran. They contain no sensitive request payloads,
are not persisted, and are cleared when the connection or wallet closes.

## Transaction review

Every `build_transaction` request requires its own explicit confirmation and
must remain bound to the original request. It cannot be approved through a
permission batch or an automatic **Allowed** rule. Existing rules that would
bypass mandatory review are reset to **Ask**.

Genesix must review the complete supported transaction without dropping,
rounding, or substituting fields. Amounts, fees, gas, nonces, and limits retain
their exact integer values, including on Web. XWF's typed values pass directly
to the SDK without ordinary JSON reparsing that could lose precision.

For contract invocations, the review includes the entry contract and function,
deposits, parameters, fee and gas limits, and the requested inter-contract
permission. That permission must be explicit and is preserved exactly:

- `none` permits no inter-contract calls under that permission model.
- `all` permits calls to any contract.
- `specific` permits only the listed contract/function combinations.
- `exclude` permits everything outside those combinations; nested selectors
  are negated as a whole. An empty `specific` list permits no external calls,
  while an empty `exclude` list permits all.

Broad permissions can affect assets or existing positions beyond the deposits
shown. `all` and `exclude` require a warning, and `none` is not a guarantee of
safety or absence of delegated code execution. Genesix does not simulate
contracts, predict economic outcomes, or narrow permissions on the user's
behalf. These permissions apply only to the transaction being reviewed.

## Capabilities and limits

| Platform | Connections |
| --- | --- |
| Desktop and Android | Local XSWD server and relayed connections. |
| iOS and Web | Relayed connections only. |

| Capability | Policy |
| --- | --- |
| Public information, verification, and estimates | Supported; may be preauthorized for the connection. |
| Private wallet data | Supported with explicit consent, including disclosure of private node information where applicable. May be preauthorized. |
| Application storage | Reads and writes to the application's isolated storage may be preauthorized. |
| Wallet events | Subscription and unsubscription may be preauthorized independently. |
| Transactions | Transfer, burn, multisig, contract invocation, and deployment are supported with individual, complete review. This also applies on Web. |
| Offline/unsigned transaction stages and signing | Unavailable without dedicated orchestration and review. |
| Proofs, decryption, rescan/cache operations, network-mode changes, and asset tracking mutations | Unavailable without dedicated orchestration and review. |
| Blob transactions, explicit signers, and unknown or lossy transaction fields | Rejected. |

Unavailable capabilities stay rejected until their validation, consent, and
execution flows are supported. Changing dependencies alone does not enable them.

Validation limits the size and complexity of untrusted requests before decoding
or display. Oversized or invalid data is rejected; native wallet validation
remains authoritative. Full sensitive details are revealed only through an
explicit user action. Malformed requests and unknown methods also close their
originating connection without affecting other sessions.

Keep this support matrix, method policies, and regression tests aligned when
XWF or the SDK changes. Web review changes need both
[review tests](../test/xswd_web_permission_review_test.dart) and
[real relayer integration](../integration_test/xswd_web_relayer_test.dart);
unit tests alone do not verify the complete Web boundary.

Detailed failure handling belongs in [error-handling.md](error-handling.md),
wallet runtime lifecycle in [runtime-events.md](runtime-events.md), and build
and test procedures in the [README](../README.md#test).
