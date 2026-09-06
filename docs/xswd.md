# XSWD policy and support matrix

This document is the canonical Genesix policy for XSWD (XELIS Secure WebSocket
DApp) connections, permission requests, transaction review, and
deferred XSWD capabilities. It describes the behaviour that the application
must enforce; it is not a protocol specification or a product roadmap.

Read it before changing XSWD callbacks, permission policy, review UI, relayer
handling, or the `xelis_dart_sdk` / `xelis_wallet_flutter` XSWD contract.

## Architecture and trust boundaries

An XSWD local server accepts local application sessions. A relayed connection
uses a QR, paste, or deep-link payload to establish an application session
through a relayer. In both cases, a session is untrusted until Genesix has
validated the request and obtained the user's decision.

Responsibilities are deliberately split:

- `xelis_wallet_flutter` (XWF) owns the native transport, callback lifecycle,
  structured XSWD failures, and the native wallet boundary.
- `xelis_dart_sdk` owns the public RPC models and typed deserialization.
- Genesix owns platform policy, permission normalization, fail-closed request
  validation, review presentation, and the user decision.

XSWD QR, paste, deep-link, request, encryption-key, and transaction payloads
are sensitive. They must not be placed in ordinary logs, support references,
analytics, crash reports, route state, or user-facing errors. A request that is
malformed, unsupported, or not fully and losslessly reviewable is rejected;
the callback/session then follows the XWF lifecycle and failure policy.

The application ID is persisted identity metadata, not authority over a live
connection. Genesix closes and edits a session only with the opaque
`XelisXswdSessionReference` attached by XWF to the exact application projection.
This keeps simultaneous local and relayed instances distinct even when their
application IDs collide, and makes stale, reconstructed, reconnected, or
other-wallet projections fail closed.

Application-detail navigation carries only that opaque reference in memory.
Its GoRouter codec serializes a constant non-restorable sentinel: no native
token, application ID, name, URL, permission, or request data enters route
restoration or diagnostics. A restored route receives a detached reference and
shows the disconnected/not-found state; it never falls back to application-ID
lookup. Ordinary imperative navigation retains the live reference and resolves
it again against the current wallet's application list.

## Current support matrix

| Surface | Current policy |
| --- | --- |
| Desktop and Android | Local XSWD server and relayed application sessions are supported. |
| iOS | Local XSWD server is unavailable; relayed sessions are supported. |
| Web | Local XSWD server is unavailable; relayed sessions and lossless `build_transaction` review are supported through XWF 0.3. |
| Public information, verification, and estimates | Supported by the standard permission review. They may be prefetched and persisted after explicit approval. Permission names are the unprefixed `WalletMethod.jsonKey` values, such as `get_version`. |
| Private wallet data | Balance, address, nonce, asset, transaction, and `network_info` reads are supported by the standard permission review. The latter includes the connected daemon endpoint, which is not necessarily public. These methods may be prefetched and persisted only after the UI identifies their wallet-data effect. |
| Application storage | The XSWD application's isolated database reads and writes are supported, prefetchable, and persistable after explicit approval. |
| `build_transaction` | A one-time, structured, lossless review only. It cannot be prefetched or persisted as `Accept`; legacy persisted `Accept` policies are normalized to `Ask`. |
| Supported builders | Transfer, burn, multisig, contract invocation, and contract deployment, only when every field is rendered and validated. |
| Unsupported builders/fields | Blob builder, explicit signers, and non-`NoInterContractPermission` permissions are rejected. |
| Unsupported wallet methods | Offline/unsigned transaction stages, signing, proofs, decryption, rescan/cache operations, network-mode changes, and asset tracking mutations are rejected because Genesix has no dedicated orchestration and review for their effects. They cannot be prefetched or persisted as `Accept`. |

For `build_transaction`, all amounts, fees, gas values, nonces, and limits stay
as `BigInt`. The review must render the exact typed values, including
`FeeBuilder`, `BaseFeeMode`, and `feeLimit`. An unknown RPC cell, primitive,
permission, fee mode, or builder is a refusal, never a permissive fallback.

Every SDK `WalletMethod` has one explicit support, persistence, prefetch, and
effect classification. Stored `Accept` policies for non-persistable and unknown
methods are normalized to `Ask` before XSWD activation and when permissions are
edited. Adding an SDK method must update this exhaustive classification before
analysis can pass.

Review parsing is also resource-bounded before the SDK or UI walks untrusted
structures. Genesix rejects payloads above 3 MiB of cumulative text characters,
individual strings above 2 MiB, typed structures deeper than 64 levels or larger than
300,000 nodes, transaction collections above the protocol's 255-entry bound,
typed RPC graphs above 4,096 value cells, and requests containing more than 64
opaque addresses to validate. These conservative limits are fail-closed DoS
controls derived from XELIS 1.25's 1 MiB transaction, 256 KiB contract-parameter,
and 255-transfer bounds; changing them requires protocol evidence and boundary
tests. Prefetch permission lists must contain unique methods and cannot exceed
the number of methods in the SDK catalogue. Both initial consent and permission
editing explain the effect and the absence of future prompts for persistent
approval.

Before SDK integer or hexadecimal decoding, unsigned decimal strings must be
canonical and fit their declared width (at most 20 digits for u64, 39 for u128,
and 78 for u256). Invocation parameters share a 256 KiB scalar-content budget:
decoded byte lengths, UTF-8 text lengths, and fixed-width primitive storage.
This is a pre-decoding application defence, not a reproduction of the complete
native `data_size_in_bytes` verifier; native validation remains authoritative.
Long prefetch reasons use a bounded preview and reveal the exact full text in
a segmented view only after explicit action. Standard permission parameters
follow the same disclosure rule: passive rendering inspects only a bounded
prefix of the validated tree, while complete, exact `BigInt`-preserving JSON is
serialized and rendered in segments only after explicit action. Unsupported
permissions in the application detail explicitly explain that requests are
rejected even under `Ask`.

Closing one application rejects its pending approval before awaiting native
transport shutdown. New requests from that application are rejected while the
close is pending; another application's approval is preserved. A completed
close from a replaced wallet session cannot update the new session's UI.
Stopping XSWD waits for exact application closes already in progress. A close
requested during that stop follows its result: successful stop already revokes
the session, while a failed stop retries only the requested opaque session.
These comparisons use the opaque session reference, so an ID collision cannot
clear, edit, or close the other connection. A cancel or disconnect callback
for another opaque session may refresh application state, but it never replaces
or rejects the active review and never clears that review's notification.
XWF performs native cancellation and invalidation before diagnostic Dart
notifications. An exact-session cancellation preempts its active decision;
an unrelated session's notification can be deferred or omitted under overload.
Do not use notification delivery as acknowledgement of native cleanup.

The application-request callback is an admission proposal, not yet a live
session capability. Genesix can review and accept or reject it, but close and
permission editing require the same reference to appear in a fresh XSWD state
read after admission. This preserves callback-to-list identity without treating
an application that upstream has not inserted yet as operable.
If a permission payload cannot be parsed, Genesix returns `Reject` first, then
performs that fresh state read and closes only the matching opaque session.
An absent match is treated as an already disconnected session; application ID
is never used as a fallback authority.

## Lossless Web transaction review

XWF 0.3 provides an immutable typed XSWD tree with exact `BigInt` integers.
Genesix adapts this tree directly to SDK 0.36, without JSON reparsing, so Web
review must preserve exact numeric values above `2^53 - 1` through `u64::MAX`.

Regression coverage combines the [Chrome review tests](../test/xswd_web_permission_review_test.dart)
with the [real relayer integration](../integration_test/xswd_web_relayer_test.dart).
Keep the latter in validation after XWF, SDK, FRB or Flutter changes affecting
numeric projection, review binding or lifecycle; typed DTO tests alone do not
exercise the Rust/WASM-to-review boundary. See the [test instructions](../README.md#test).

The integration uses offline, unfunded wallets and covers Flutter Web JavaScript
plus Rust/WASM in Chrome, not network broadcast, Flutter `--wasm`, or every
browser. Malformed-session cleanup does not guarantee delivery of the rejection
response to the relayer before transport closure.

Immediate peer-only socket close detection is not guaranteed: upstream can
defer reading that close while a permission callback is pending. XWF bounds
callback waits and closes the exact transport on application-requested shutdown;
completion of that operation, not the initial click, is the transport-closed
guarantee.

## Deferred work register

Every deferred item remains fail-closed. “Owner” identifies the layer that
must change first; it does not assign a delivery date.

| Item | Current fail-closed behaviour and risk avoided | Owner and prerequisites | Required evidence / exit signal |
| --- | --- | --- | --- |
| Local server on Web/iOS | Do not start a local server; avoids unsupported transport/platform behaviour. | XWF/upstream must support the platform transport; Genesix needs a network security review. | Platform integration tests and a reviewed transport threat model. |
| Offline, unsigned, and finalization flows | Reject `build_transaction_offline`, unsigned build/finalize/sign requests; avoids approving disconnected stages that are not bound to a final payload. | SDK/XWF contract and Genesix need a step-by-step review model with exact payload binding. | Tests that tamper with every stage plus end-to-end approve/reject/cancel coverage. |
| Data signing | Reject `sign_data`; avoids blind signatures without a canonical domain, content, and context presentation. | SDK/XWF must expose a canonical signing envelope; Genesix needs a dedicated signing UX and threat review. | Domain-separation, hostile-content, approve/reject, and no-sensitive-log tests. |
| Blob transactions | Reject `BlobBuilder`; avoids approving content whose size, commitment, meaning, and consequences cannot be reviewed. | SDK/XWF must expose review-safe metadata and binding; Genesix needs a dedicated blob review. | Boundary-size, commitment mismatch, and full review-to-broadcast tests. |
| Explicit signers | Reject non-empty signers; avoids revealing or handling structures that can contain private-key material. | Upstream must provide a public, non-secret signer projection; Genesix needs a documented authority model. | Fixtures proving no private material reaches UI/logs plus signer-authority tests. |
| Advanced inter-contract permissions | Reject every permission except `NoInterContractPermission`; avoids opaque `all`, `specific`, or `exclude` authority. | SDK must expose semantics sufficient for review; Genesix needs a contract/target scope UI. | Exhaustive variant tests, semantic rendering tests, and a security review. |
| Persistent non-standard authorization | Normalize stored `Accept` to `Ask` and deny prefetch for dedicated-review, unsupported, and unknown methods; avoids durable or silent approval without matching review semantics. | Intentional product/security decision, new threat model, revocation and migration design. | Explicitly approved security design and regression tests; this is not a routine TODO. |
| Full Forui modernization | Keep the XSWD surface transitional; preserve permission and review behaviour when changing UI components. | Genesix UX workstream, independent of XSWD contract support. | Separate UX plan, accessibility checks, and platform visual QA. |

Native packaging and Apple lock regeneration are tracked in the
[native release validation instructions](../README.md#native-release-validation),
not as deferred XSWD capabilities.

## Maintenance

- Revisit this document whenever XWF, the SDK, or `WalletMethod` changes.
- Keep the support matrix, the code allowlists, and negative tests aligned in
  the same change.
- Keep detailed failure ownership in [error-handling.md](error-handling.md)
  and runtime stream lifecycle in [runtime-events.md](runtime-events.md); do
  not duplicate their full policies here.
- The deferred-work register is canonical. Other documents should link here
  rather than copy it.
