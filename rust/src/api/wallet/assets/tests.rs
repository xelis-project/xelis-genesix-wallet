use anyhow::{anyhow, Result};
use futures::lock::Mutex as AsyncMutex;
use parking_lot::Mutex;
use serde_json::json;
use xelis_common::asset::{AssetData, AssetOwner, MaxSupplyMode};
use xelis_common::config::XELIS_ASSET;
use xelis_common::crypto::Hash;

use super::{asset_metadata_json, resolve_asset_data, resolve_asset_hash};

enum CacheOutcome {
    Hit(AssetData),
    Miss,
    Error,
}

enum DaemonOutcome {
    Success(AssetData),
    Error,
}

struct FakeAssetDataSource {
    cache: Mutex<CacheOutcome>,
    daemon: DaemonOutcome,
    persistence_fails: bool,
    resolution_lock: AsyncMutex<()>,
    events: Mutex<Vec<&'static str>>,
    persisted: Mutex<Option<AssetData>>,
}

impl FakeAssetDataSource {
    fn new(cache: CacheOutcome, daemon: DaemonOutcome, persistence_fails: bool) -> Self {
        Self {
            cache: Mutex::new(cache),
            daemon,
            persistence_fails,
            resolution_lock: AsyncMutex::new(()),
            events: Mutex::new(Vec::new()),
            persisted: Mutex::new(None),
        }
    }

    async fn resolve(&self) -> Result<AssetData> {
        resolve_asset_data(
            &self.resolution_lock,
            || async {
                self.events.lock().push("cache");

                match &*self.cache.lock() {
                    CacheOutcome::Hit(asset_data) => Ok(Some(asset_data.clone())),
                    CacheOutcome::Miss => Ok(None),
                    CacheOutcome::Error => Err(anyhow!("cache failure")),
                }
            },
            || async {
                self.events.lock().push("daemon");
                tokio::task::yield_now().await;

                match &self.daemon {
                    DaemonOutcome::Success(asset_data) => Ok(asset_data.clone()),
                    DaemonOutcome::Error => Err(anyhow!("daemon failure")),
                }
            },
            |asset_data| async move {
                self.events.lock().push("persist");

                if self.persistence_fails {
                    return Err(anyhow!("persistence failure"));
                }

                *self.persisted.lock() = Some(asset_data.clone());
                *self.cache.lock() = CacheOutcome::Hit(asset_data.clone());
                Ok(asset_data)
            },
        )
        .await
    }
}

fn test_asset(name: &str, ticker: &str) -> AssetData {
    AssetData::new(
        8,
        name.to_owned(),
        ticker.to_owned(),
        MaxSupplyMode::Fixed(1_000_000),
        AssetOwner::None,
    )
}

#[test]
fn asset_metadata_serializes_every_field() {
    let origin = Hash::new([1; 32]);
    let owner = Hash::new([2; 32]);
    let data = AssetData::new(
        8,
        "Example Token".to_owned(),
        "EXT".to_owned(),
        MaxSupplyMode::Mintable(1_000_000),
        AssetOwner::Owner {
            origin: origin.clone(),
            origin_id: 7,
            owner: owner.clone(),
        },
    );

    let value: serde_json::Value =
        serde_json::from_str(&asset_metadata_json(&data).unwrap()).unwrap();

    assert_eq!(
        value,
        json!({
            "name": "Example Token",
            "ticker": "EXT",
            "decimals": 8,
            "max_supply": {"mintable": 1_000_000},
            "owner": {
                "owner": {
                    "origin": origin.to_hex(),
                    "origin_id": 7,
                    "owner": owner.to_hex(),
                }
            },
        })
    );
}

#[test]
fn asset_metadata_serializes_absent_owner_and_fixed_supply() {
    let data = AssetData::new(
        0,
        "Fixed".to_owned(),
        "FIX".to_owned(),
        MaxSupplyMode::Fixed(42),
        AssetOwner::None,
    );

    let value: serde_json::Value =
        serde_json::from_str(&asset_metadata_json(&data).unwrap()).unwrap();

    assert_eq!(value["max_supply"], json!({"fixed": 42}));
    assert_eq!(value["owner"], json!("none"));
}

#[test]
fn asset_hash_defaults_to_xelis_and_accepts_custom_assets() {
    let custom = Hash::new([3; 32]);

    assert_eq!(resolve_asset_hash(None).unwrap(), XELIS_ASSET);
    assert_eq!(resolve_asset_hash(Some(&custom.to_hex())).unwrap(), custom);
}

#[test]
fn asset_hash_rejects_invalid_hex() {
    let error = resolve_asset_hash(Some("not-a-hash")).unwrap_err();

    assert!(error.to_string().starts_with("Invalid asset"));
}

#[tokio::test]
async fn asset_resolution_returns_cache_without_daemon_or_persistence() {
    let cached = test_asset("Cached Token", "CACHE");
    let source = FakeAssetDataSource::new(CacheOutcome::Hit(cached), DaemonOutcome::Error, false);

    let result = source.resolve().await.unwrap();

    assert_eq!(result.get_ticker(), "CACHE");
    assert_eq!(*source.events.lock(), vec!["cache"]);
    assert!(source.persisted.lock().is_none());
}

#[tokio::test]
async fn asset_resolution_fetches_cache_miss_then_persists_daemon_result() {
    let fetched = test_asset("Remote Token", "REMOTE");
    let source =
        FakeAssetDataSource::new(CacheOutcome::Miss, DaemonOutcome::Success(fetched), false);

    let result = source.resolve().await.unwrap();

    assert_eq!(result.get_ticker(), "REMOTE");
    assert_eq!(
        *source.events.lock(),
        vec!["cache", "cache", "daemon", "persist"]
    );
    assert_eq!(
        source.persisted.lock().as_ref().map(AssetData::get_ticker),
        Some("REMOTE")
    );

    let cached_result = source.resolve().await.unwrap();

    assert_eq!(cached_result.get_ticker(), "REMOTE");
    assert_eq!(
        *source.events.lock(),
        vec!["cache", "cache", "daemon", "persist", "cache"]
    );
}

#[tokio::test]
async fn asset_resolution_stops_when_cache_read_fails() {
    let source = FakeAssetDataSource::new(CacheOutcome::Error, DaemonOutcome::Error, false);

    let error = source.resolve().await.unwrap_err();

    assert_eq!(error.to_string(), "cache failure");
    assert_eq!(*source.events.lock(), vec!["cache"]);
    assert!(source.persisted.lock().is_none());
}

#[tokio::test]
async fn asset_resolution_does_not_persist_a_daemon_failure() {
    let source = FakeAssetDataSource::new(CacheOutcome::Miss, DaemonOutcome::Error, false);

    let error = source.resolve().await.unwrap_err();

    assert_eq!(error.to_string(), "daemon failure");
    assert_eq!(*source.events.lock(), vec!["cache", "cache", "daemon"]);
    assert!(source.persisted.lock().is_none());
}

#[tokio::test]
async fn asset_resolution_reports_persistence_failure_after_fetch() {
    let fetched = test_asset("Remote Token", "REMOTE");
    let source =
        FakeAssetDataSource::new(CacheOutcome::Miss, DaemonOutcome::Success(fetched), true);

    let error = source.resolve().await.unwrap_err();

    assert_eq!(error.to_string(), "persistence failure");
    assert_eq!(
        *source.events.lock(),
        vec!["cache", "cache", "daemon", "persist"]
    );
    assert!(source.persisted.lock().is_none());
}

#[tokio::test]
async fn concurrent_asset_resolution_fetches_and_persists_only_once() {
    let fetched = test_asset("Remote Token", "REMOTE");
    let source =
        FakeAssetDataSource::new(CacheOutcome::Miss, DaemonOutcome::Success(fetched), false);

    let (first, second) = tokio::join!(source.resolve(), source.resolve());

    assert_eq!(first.unwrap().get_ticker(), "REMOTE");
    assert_eq!(second.unwrap().get_ticker(), "REMOTE");

    let events = source.events.lock();
    assert_eq!(events.iter().filter(|event| **event == "daemon").count(), 1);
    assert_eq!(
        events.iter().filter(|event| **event == "persist").count(),
        1
    );
}
