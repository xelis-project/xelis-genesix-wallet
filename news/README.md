# Genesix News Feed

This folder is the static news feed consumed by the wallet home screen.

The app reads `news/index.json` from GitHub Pages by default:

```text
https://xelis-project.github.io/xelis-genesix-wallet/news/index.json
```

When the remote feed cannot be fetched, the app falls back to the last cached
feed. If there is no cache, it falls back to the bundled `news/index.json`
shipped with the app.

The feed is public and must never contain user-specific data, wallet addresses,
balances, seed phrases, transaction payloads, or signing instructions.

Each item should be useful for wallet operation: security alerts, wallet
releases, network incidents, protocol updates, or important Genesix/XELIS
announcements. Generic market news and price predictions do not belong here.

Localized `title`, `summary`, and link `label` maps must include an `en`
fallback. Only languages supported by the app are accepted:

```text
ar bg de en es fr hi it ja ko ms nl pl pt ru tr uk zh
```

Allowed item types are:

```text
update security network announcement
```

Allowed severities are:

```text
info warning critical
```

Critical news must define `expiresAt`; it cannot be dismissed in the app and
will disappear only after expiration.

## Item identity and revisions

The `id` is the stable identity of a news item. When a user dismisses a
non-critical news item, the app stores this `id` locally and filters that item
from the home feed.

Dismissed IDs are pruned after a successful remote feed fetch. IDs that no
longer exist in the active feed are removed from local storage.

Keep the same `id` for small corrections such as typos, wording changes,
translations, or a fixed link. Users who already dismissed the item will not see
it again.

Use a new `id` when the change is materially new information and should reappear
for users who dismissed the previous item. For example:

```text
2026-06-xelis-node-1-22-2
2026-06-xelis-node-1-22-2-r2
```

The top-level `version` field is the feed schema version, not the editorial
revision of a specific item.

## Links

Links are optional. A news item can be purely informational and have no external
action. When links are present, the app uses the first valid link as the primary
dialog action.

Allowed link hosts are intentionally restricted to official XELIS and GitHub
domains. Update `lib/features/news/domain/news_feed_contract.dart` only when a
new official domain is needed; both the app parser and the validation tool use
that shared contract.

## Retention

Keep `news/index.json` focused on active or recent items. The app only displays
up to three visible items on the home card and parses at most 50 feed entries.

Do not let the active feed grow indefinitely. Remove expired or obsolete items
after a reasonable grace period. If long-term history is needed, store it outside
the active feed, for example:

```text
news/archive/2026.json
```

The app should not read archive files for the home feed.

## Validation

Validate the feed locally before opening a PR:

```shell
dart run tool/validate_news_feed.dart
```

The GitHub Actions workflow `.github/workflows/news_feed.yml` runs the same
validation for PRs and deploys the `news/` directory to GitHub Pages from
`main`.

Example:

```json
{
  "id": "2026-06-wallet-update",
  "publishedAt": "2026-06-23T10:00:00Z",
  "expiresAt": null,
  "type": "update",
  "severity": "info",
  "title": {
    "en": "New Genesix release",
    "fr": "Nouvelle version de Genesix"
  },
  "summary": {
    "en": "This version improves synchronization and fixes wallet UI issues.",
    "fr": "Cette version améliore la synchronisation et corrige des détails d'interface."
  },
  "targets": {
    "networks": ["mainnet", "testnet"],
    "platforms": ["android", "ios", "windows", "linux", "macos", "web"],
    "minAppVersion": "0.2.0",
    "maxAppVersion": null
  },
  "links": [
    {
      "label": {
        "en": "View release",
        "fr": "Voir la release"
      },
      "url": "https://github.com/xelis-project/xelis-genesix-wallet/releases"
    }
  ]
}
```
