# Error handling

Genesix owns the recovery, support logging, localization, and presentation
policy for failures surfaced by `xelis-wallet-flutter`. The package owns the
native classification and the versioned `XelisWalletException` contract.

## Failure flow

```text
xelis-wallet / xelis-common / bridge / Genesix dependency
                         |
                         v
                caught error + stack
                         |
                         v
                 recordAppFailure
                  /             \
                 v               v
       safe support log       AppFailure
                                  |
                                  v
                        WalletEffect.failure
                                  |
                                  v
                    localized sticky toast
                    + selectable reference
```

The layer that decides how to recover or present the failure calls
`recordAppFailure` exactly once. It then emits the returned `AppFailure`; toast
and presentation layers do not log it again.

## Safe application contract

`AppFailure` contains only reviewed support metadata:

- the Genesix `AppFailure` contract version and exception type;
- the optional originating contract version for structured package failures;
- source, operation, and stable code;
- the original package support ID (`XWF-...`) or a Genesix-owned ID
  (`GNX-...`);
- optional native kind and numeric code;
- an application category used for localized presentation and recovery.

It never retains the original exception, an arbitrary error object, a stack
trace, or `XelisWalletException.diagnosticMessage`. Its `toString()` and
`supportReference` are therefore safe for standard support handling.

The visible reference deliberately contains source, operation, code, and ID.
This lets a user report enough information to identify the responsible layer
even when no diagnostic-log export is available.

## Catching a failure

```dart
try {
  await walletOperation();
} catch (error, stackTrace) {
  final failure = recordAppFailure(
    error,
    stackTrace,
    operation: 'wallet.operation',
    applicationCode: 'wallet_operation_failed',
    contextBuilder: () => 'walletPath=$auditedWalletPath',
  );

  ref
      .read(walletEffectBusProvider.notifier)
      .emit(WalletEffect.failure(failure: failure));
}
```

For `XelisWalletException`, `recordAppFailure` preserves the package source,
operation, code, and `XWF-...` ID. The application operation and code are used
only for unrelated Dart, storage, platform, or application failures; those
receive a new `GNX-...` ID and are not disguised as native errors.

An intentionally silent background attempt may use `appFailureFromError` to
make the same support-safe mapping without writing a retained support record.
That result is for recovery/state decisions only: it must not be displayed, and
its support ID must not be offered to a user because no matching support record
was written. Any failure shown to the user must be mapped with
`recordAppFailure` exactly once.

## Choosing operation and application code

The two application identifiers passed to `recordAppFailure` are currently
authored explicitly at each recovery boundary. They are required because the
same `catch` can receive either a structured `XelisWalletException` or an
unrelated Dart/dependency failure. They are fallback metadata, not overrides:

- for a `XelisWalletException`, the package-owned source, operation, code, and
  support ID always win;
- for any other error, Genesix uses the supplied operation and application code
  and creates a `GNX-...` support ID.

Choose them by contract, not by the wording of the caught exception:

- `operation` identifies the stable action owned by the recovery boundary. Use
  lowercase dot-delimited names such as `wallet.open` or the more precise
  `wallet.session.repository.close` when the phase affects diagnosis;
- `applicationCode` identifies the stable cause or result in lower snake case,
  such as `wallet_name_invalid` or, when no safe distinction exists,
  `wallet_open_failed`;
- `applicationCategory` independently expresses the recovery/localization
  decision. Do not encode user-facing prose in either identifier;
- keep one application fallback meaning per `try` block. If copying, opening,
  and persisting can fail independently and need different diagnosis or
  recovery, split those phases rather than labeling every failure as open;
- reuse an existing identifier only when it has the same semantics. Never build
  an identifier from an exception message, runtime type, route, widget, path,
  amount, or other contextual value;
- treat a new or renamed identifier as a support-contract change and cover its
  native-preservation or application-fallback behavior with a focused test.

As the application-owned catalog grows, these free-form fallback pairs can be
migrated to feature-owned typed constants or a small `AppFailureContext` value
object. That hardening should be done as one coherent migration; duplicating the
package's typed operation/code catalog inside Genesix would create two sources
of truth and must be avoided.

For an application fallback, `source == genesix` means that Genesix owns the
classification record. It does not prove that the deepest failure originated
inside Genesix: the exception type, stack trace, stable operation, and audited
diagnostic context remain the support evidence for locating a filesystem,
plugin, storage, or other dependency failure.

## Logging and diagnostic context

The standard support record contains only the safe `AppFailure` fields. A Dart
stack trace and an explicitly audited `contextBuilder` are added only when the
debug diagnostic policy is enabled.

Paths, amounts, hashes, and sanitized endpoints can be useful during local
development and may be supplied through that explicit context builder.
Passwords, seeds, private keys, tokens, signing material, authenticated URLs,
and complete external payloads remain forbidden in every mode.

Genesix never logs `diagnosticMessage` automatically, including in debug. The
package also redacts mnemonic validation details that could contain a word from
the entered seed. Any future tool that exposes native diagnostics must remain a
separate, deliberate support workflow with per-operation review and redaction.

## UI and recovery

`ToastProvider.showFailure` maps the application category to localized copy.
The native message and `error.toString()` are never fallback UI text. The
support reference stays raw in `ToastContent`, is localized only while being
rendered, and makes the toast sticky until dismissal. The main message is
displayed in full. The toast grows naturally up to a viewport-relative limit;
only extreme content scrolls internally. Clicking or tapping the muted support
reference copies the raw, support-safe reference without copying its localized
label or any privileged diagnostic.

Recovery and retry decisions use stable categories or package codes, never
text parsing. A new user action creates a new attempt and, if it fails, a new
support ID. Create, open, import, and password verification are not retried
automatically.

Wallet connection retries are deliberately narrower: a disconnect with no
recorded failure may reconnect, and a structured `network.failed` may retry.
`network.mismatch`, daemon rejection, invalid input, conflicts, internal or
bridge failures, and unrelated Dart failures never retry automatically. A
visible connection attempt is recorded and shown once; later automatic attempts
remain silent and do not produce support-log entries every five seconds. If the
native cleanup of one of those silent attempts itself returns a retryable
network or operation-in-progress failure, Genesix schedules the next attempt;
the same cleanup failure on an explicit user action remains visible and stops.

The typed `XelisWalletSyncIssue` event carries a structured package failure.
Genesix passes that failure unchanged to `recordAppFailure`, preserving its
source, operation, code, native discriminants, and `XWF-...` id. Its privileged
diagnostic message is never read. Because upstream can emit the event for a
recoverable per-asset failure, it remains non-terminal: only a following typed
`XelisWalletOffline` event controls reconnection.

A typed event-stream lag records one package failure for the coalesced episode
and triggers authoritative state reconciliation without disconnecting. Runtime
close is connection-terminal. Business close uses the distinct
`wallet.business_events.stream` operation, preserves the package `XWF-...`, and
does not mark the network failed. Each channel's `Closed`, stream error, and
following `onDone` paths share one claim so support logging and UI presentation
happen at most once. Expected cancellation is silent. The complete lifecycle is
documented in [`runtime-events.md`](runtime-events.md).

`WalletEffect.error` and `ToastProvider.showError` remain available for
explicitly authored, localized validation messages while legacy producers are
migrated. They must not receive strings obtained from caught exceptions.

## Prepared transaction broadcast outcomes

Standard, non-multisig transfer and burn flows keep the exact authored
`XelisWalletPreparedTransaction` from preparation through review, broadcast, or
explicit discard. Its hash is safe review and support metadata, but is not a
replacement for that capability. Multisig finalization also returns an authored
prepared capability and follows the same ownership rule.

Before a standard broadcast, the UI authenticates the user and then rereads the
current review. It proceeds only while confirmation is still active and both
the prepared-object identity and transaction hash match what the user reviewed.

The package returns one of five exhaustive value outcomes. Genesix applies the
following ownership and recovery policy:

| Package outcome | Prepared transaction and review | UI and recovery |
| --- | --- | --- |
| `XelisWalletBroadcastSubmitted` | Consumed; mark the review broadcasted. | Show the normal success message. |
| `XelisWalletBroadcastRetryable` | Restored by the package; retain the same prepared object and review. | Show the structured failure and allow an explicit retry of that exact transaction. |
| `XelisWalletBroadcastRejected` | Consumed; reset the review. | Show the structured failure, leave the review screen, and require a newly prepared transaction. |
| `XelisWalletBroadcastLocalFailure` | Consumed; reset the review. | Show the structured failure, leave the review screen, and require a newly prepared transaction. |
| `XelisWalletBroadcastSubmittedNeedsResync` | Consumed because submission succeeded; mark the review broadcasted. | Show the structured failure and request exactly one authoritative rescan. |

Every non-clean package outcome carries a structured
`XelisWalletException`. The wallet command boundary passes it to
`recordAppFailure` exactly once, preserving its package-owned source,
operation, code, and `XWF-...` support ID. The resulting `AppFailure` is passed
to `ToastProvider.showFailure`; neither the review screen nor the toast records
it again. A clean `submitted` outcome has no failure to record.

The rescan for `submittedNeedsResync` has a separate error boundary. Its failure
is recorded and emitted as `wallet.rescan` / `wallet_rescan_failed`, without
recording the broadcast XWF again. Regardless of the rescan result, the command
still returns `submittedNeedsResync`: a transaction already submitted must
never become retryable merely because local reconciliation failed.

Before broadcast, closing a standard review discards the exact prepared object.
Genesix resets and closes the review only after that discard succeeds; on
failure it retains the review so ownership is not silently lost. A pending
multisig signing request is likewise cancelled only through its exact authored
request object.

## Attached-data disclosure

Home/history lists, route codecs, and passive wallet events retain only
attached-data presence, encryption/flag metadata, and a safe top-level kind.
They never retain the value. While a transaction detail is mounted, Genesix may
read that exact confirmed or pending transaction by hash with detailed
disclosure and present its lossless `XelisDataElement` after user interaction.
The value must not enter navigation restoration, analytics, crash reports,
support references, or ordinary logs.

An integrated address is different from a decrypted transaction payload: its
data is visible to anyone holding the address and has no
`XelisWalletExtraDataFlag`. UI code must not fabricate a transaction flag merely
to reuse a widget. A prepared transfer is different again: its payload can be
read only through the exact prepared-object capability and transfer index. A
legacy review without that capability remains metadata-only.

AddressBook identity follows the complete destination. History association may
name a contact only after an exact base-plus-`DataElement` match. Base-only and
ambiguous results remain unnamed hints so two exchange deposit references can
never be silently conflated.

## Session and authentication lifecycle

Create, seed recovery, private-key recovery, open, address read, seed read,
password verification, close, and dispose use the authored wallet handle. The
generated wallet delegate remains private to `NativeWalletRepository` only for
feature groups that have not yet migrated; it must never be used to close or
dispose the wallet or recreate the removed JSON business-event stream.

Session replacement always follows this order:

1. stop XSWD and prepare the runtime;
2. await the authored wallet `close()`;
3. clear the active session;
4. call `dispose()` to release the opaque local handle;
5. only then create or open the next wallet.

A native close or dispose failure is surfaced with its original support ID and
blocks the current replacement attempt. A repository opened but not attached
to a session is closed and disposed in the failure path, including when secure
storage or address persistence fails.

## XSWD lifecycle and failures

Genesix consumes only the authored `XelisXswd*` contract from the package root
library. The package privately adapts generated callbacks and reports start,
stop, state reads, relayer addition, application-session close, and permission
updates as structured `XelisWalletException` failures with exact
`wallet.xswd.*` operations.

The XSWD controller maps and records each visible failure exactly once, emits a
`WalletEffect.failure`, and returns a success flag to QR and paste flows. Those
presentation flows do not catch and re-record a native failure. Background
state reads use the same rule and return an empty projection after emitting the
structured failure, so widgets never interpolate caught exception text.

Permission and prefetch request JSON remains an opaque, potentially sensitive
RPC payload interpreted by Genesix and `xelis-dart-sdk`. Complete QR, paste,
deep-link, request, and encryption-key payloads never enter standard logs,
support references, analytics, crash reports, or toasts. Callback failures and
timeouts fail closed at the package boundary and do not cross into Rust or
native diagnostics.

`build_transaction` is accepted only after a complete structured review and
only for the current request. Transaction and signing methods without a
dedicated lossless review are rejected. They cannot be prefetched, persisted as
`Accept`, or restored as a durable authorization; stored legacy `Accept`
policies for those methods are normalized to `Ask` before XSWD activation.

Wallet names are validated as portable path leaves and resolved below the
selected network directory before filesystem or web-storage access. Invalid
names never reach the native wallet and are represented as a Genesix
`invalidInput` failure without retaining the rejected value.

## Password changes and biometric credentials

The native wallet is the source of truth for its password. Genesix checks the
wallet-scoped biometric marker before changing it and updates secure storage
only when biometric access is enabled for that exact network and wallet name.
Passwords are passed unchanged; whitespace is never trimmed from a credential.

The currently locked `xelis-wallet` password update performs multiple storage
writes without an exposed transactional rollback. Genesix therefore never
attempts an automatic reverse password change after native success. If the
biometric credential cannot be updated, it disables biometric access and
awaits deletion of the marker and cached credential. The UI then reports one
of two explicit partial outcomes: cleanup completed, or cleanup incomplete.
Both state that the new native password is active and retain one support-safe
failure reference. No password enters `AppFailure`, diagnostic context, or UI.
The change-password dialog cannot be dismissed while this non-atomic native
operation is in flight, so its final or partial result is always presented.

An authentication failure is known to occur before those writes and remains a
normal failure. Any other native failure is conservatively reported as an
indeterminate password state because a dependency storage error can occur
between its separate writes. Genesix does not synchronize biometric storage,
does not retry, and tells the user to retain both passwords and contact support.
The durable fix is an atomic multi-key transaction in `xelis-wallet`; this
consumer safeguard should be revisited once the locked dependency provides it.
