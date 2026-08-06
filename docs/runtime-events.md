# Wallet event subscriptions

Genesix consumes two deliberately separate authored wallet event channels:

- the runtime channel is connection-scoped and owns connection and
  synchronization state;
- the business channel is session-scoped and owns transactions, pending
  transactions, balances, and assets, including while the wallet is offline.

Both are pull-driven, use package-owned DTOs, and expose lossless `BigInt`
generation/sequence values. Genesix no longer parses wallet-event JSON or owns
a local event union.

## Runtime flow

```text
xelis-wallet broadcast receiver
             |
             v
xelis-wallet-flutter pull-driven subscription
  generation + sequence + typed event/failure
             |
             v
NativeWalletRepository.subscribeRuntimeEvents
             |
             v
WalletRuntime generation-scoped consumer
             |
             v
WalletRuntimeState + WalletEffect + support log
```

The business path is parallel but calls
`NativeWalletRepository.subscribeBusinessEvents` once per opened wallet
session. It is not rotated with daemon connections.

Each subscription is pull-driven and single-listener. Genesix processes only
one frame at a time. The runtime consumer checks repository, connection
request, subscription identity, and `BigInt` generation; the business consumer
checks repository, subscription identity, and generation. Both repeat their
checks after every asynchronous boundary, so a stale handler cannot update
current state or emit a late UI effect.

## Connection rotation

Every connect or reconnect uses this order:

1. increment the application request id and invalidate the old consumer;
2. cancel the Dart iterator and native subscription, then await their drain;
3. await native `setOffline`;
4. create and start listening to a fresh runtime subscription;
5. call native `setOnline`;
6. hydrate authoritative wallet state and confirm native online status.

The subscription starts before `setOnline`, so no early native event is lost.
An `Online` event received before `setOnline` succeeds is not allowed to mark
Genesix connected; the post-call online check completes that transition.

Disconnect and offline mode cancel only the runtime subscription. They keep the
session-scoped business channel alive for local wallet events. Session replacement,
clear, disposal, and `prepareForClose` invalidate and cancel both channels
before the native wallet is closed.

Session lifecycle and network lifecycle use separate monotonic identifiers.
Consequently, a newer session replacement can supersede an older pending clear
without being erased by its late completion. Conversely, once clear,
`prepareForClose`, or disposal starts, reconnect, disconnect, offline-mode, and
automatic-retry intents remain blocked until a newer session is installed.

## Event policy

| Typed event | Genesix behavior |
| --- | --- |
| `XelisWalletOnline` | Mark connected only for the active successful request. |
| `XelisWalletOffline` | Mark offline and use the conservative reconnect policy. |
| `XelisWalletSyncIssue` | Preserve and record its XWF failure once; remain non-terminal until an `Offline` event. |
| `XelisWalletTopoheightChanged` | Store the lossless `BigInt` topoheight. |
| `XelisWalletRescanStarted` | Mark rescan active. |
| `XelisWalletHistorySynced` | Apply topoheight, clear rescan state, and refresh history. |
| `XelisWalletEventStreamDegraded` | Keep the connection, record one failure per coalesced lag episode, and reconcile authoritative state. |
| `XelisWalletEventStreamClosed` | Claim the terminal state once, record its XWF failure, mark the runtime failed, and release the subscription. |

| Typed business event | Genesix behavior |
| --- | --- |
| `XelisWalletNewTransaction` | Refresh multisig/assets/history and emit the matching notification. |
| `XelisWalletNewPendingTransaction` | Refresh multisig/assets/balances/history and emit the pending notification. |
| `XelisWalletBalanceChanged` | Re-read authoritative balances. |
| `XelisWalletNewAsset` | Re-read authoritative SDK metadata while retaining the authored lossless event contract. |
| `XelisWalletAssetTracked` / `XelisWalletAssetUntracked` | Reconcile metadata and tracked balances. |
| `XelisWalletBusinessEventStreamDegraded` | Keep network state unchanged and coalesce one wallet-state reconciliation. |
| `XelisWalletBusinessEventStreamClosed` | Preserve its XWF reference once and degrade business notifications without marking the connection failed. |

Lossless runtime and business integers displayed in the UI must use the shared
`formatBigInt` helper. The pinned `intl 0.20.2` `NumberFormat` throws when
given a `BigInt` directly, while converting values beyond JavaScript's safe
integer range to `int` would make the Web representation lossy. Revalidate
this constraint when `intl` is upgraded.

Runtime lag reconciliation reloads balances, known assets, multisig state,
daemon topoheight, history, and synchronization status. Business lag reloads
wallet-owned balances, assets, multisig, and history without reading daemon
topoheight or changing connection state. Repeated lag frames request one
trailing pass instead of starting parallel reads.

The native skipped count covers the unfiltered upstream wallet-event feed, not
only the typed events selected for that subscription. Genesix therefore does
not interpret it as an exact number of lost runtime or business events; it
reconciles conservatively because relevant loss cannot be excluded.

## Errors and diagnostics

Embedded package failures are passed unchanged to `recordAppFailure`. This
preserves source, operation, stable code, native discriminants, and the original
`XWF-...` support id. Genesix fallback identifiers apply only to unrelated Dart
or dependency failures.

`Closed`, a stream error, and its following `onDone` share one terminal claim,
so they cannot produce duplicate support records or toasts. Expected
cancellation invalidates the consumer first and stays silent. Native diagnostic
messages never enter application state or normal UI; see
[`error-handling.md`](error-handling.md).

The typed business stream has its own operations
`wallet.business_events.subscribe|stream|cancel`. Its failure may degrade
transaction or asset notifications, but it does not prove the native wallet is
offline and therefore cannot change the connection phase to `failed`.

## Business payload boundary

Every Rust `u64` in transaction and asset events remains a Dart `BigInt`,
including amounts, fees, nonces, timestamps, topoheights, supplies, gas, and
asset-owner IDs. `PlaintextExtraData.shared_key` and decrypted application
payloads never cross this passive event boundary. Only the typed plaintext flag
and `hasPayload` marker are exposed.
