use std::collections::HashMap;

use super::super::models::wallet_dtos::{XelisAssetMetadata, XelisAssetOwner, XelisMaxSupplyMode};
use super::XelisWallet;
use anyhow::{anyhow, Context, Result};
use log::{debug, info};
use xelis_common::asset::AssetData;
use xelis_common::config::XELIS_ASSET;
use xelis_common::crypto::Hash;
use xelis_common::serializer::Serializer;

fn asset_metadata(asset_data: &AssetData) -> XelisAssetMetadata {
    XelisAssetMetadata {
        name: asset_data.get_name().to_owned(),
        ticker: asset_data.get_ticker().to_owned(),
        decimals: asset_data.get_decimals(),
        max_supply: XelisMaxSupplyMode::from(asset_data.get_max_supply()),
        owner: Some(XelisAssetOwner::from(asset_data.get_owner())),
    }
}

fn asset_metadata_json(asset_data: &AssetData) -> Result<String> {
    Ok(serde_json::to_string(&asset_metadata(asset_data))?)
}

fn resolve_asset_hash(asset_hash: Option<&str>) -> Result<Hash> {
    match asset_hash {
        Some(value) => Hash::from_hex(value).context("Invalid asset"),
        None => Ok(XELIS_ASSET),
    }
}

impl XelisWallet {
    pub async fn has_asset_balance(&self, asset: String) -> Result<bool> {
        let asset_hash = Hash::from_hex(&asset).context("Invalid asset")?;
        let storage = self.wallet.get_storage().read().await;
        storage.has_balance_for(&asset_hash).await
    }

    pub async fn get_xelis_balance(&self) -> u64 {
        let storage = self.wallet.get_storage().read().await;
        let balance = storage
            .get_plaintext_balance_for(&XELIS_ASSET)
            .await
            .unwrap_or(0);
        balance
    }

    pub async fn get_tracked_balances(&self) -> Result<HashMap<String, String>> {
        let mut balances = HashMap::new();

        let storage = self.wallet.get_storage().read().await;

        for res in storage.get_tracked_assets()? {
            let asset = res?;
            if let Some(data) = storage.get_optional_asset(&asset).await? {
                info!("Retrieving balance for asset {}", asset);
                let balance = storage.get_plaintext_balance_for(&asset).await.unwrap_or(0);
                balances.insert(
                    asset.to_hex(),
                    xelis_common::utils::format_coin(balance, data.get_decimals()),
                );
            } else {
                info!("No asset data for {}", asset);
            }
        }

        Ok(balances)
    }

    pub async fn get_known_assets(&self) -> Result<HashMap<String, String>> {
        let storage = self.wallet.get_storage().read().await;

        let mut assets = HashMap::new();

        for res in storage.get_assets_with_data().await? {
            let (hash, asset_data) = res?;

            info!("Retrieving asset data for asset {}", hash);
            assets.insert(hash.to_hex(), asset_metadata_json(&asset_data)?);
        }

        Ok(assets)
    }

    pub async fn track_asset(&self, asset: String) -> Result<bool> {
        let asset_hash = Hash::from_hex(&asset).context("Invalid asset")?;
        let result = self
            .wallet
            .track_asset(asset_hash)
            .await
            .context("Error tracking asset")?;
        Ok(result)
    }

    pub async fn untrack_asset(&self, asset: String) -> Result<bool> {
        let asset_hash = Hash::from_hex(&asset).context("Invalid asset")?;
        let result = self
            .wallet
            .untrack_asset(asset_hash)
            .await
            .context("Error tracking asset")?;
        Ok(result)
    }

    pub async fn get_asset_decimals(&self, asset: String) -> Result<u8> {
        let asset_hash = Hash::from_hex(&asset).context("Invalid asset")?;
        let data = self.get_asset_data(&asset_hash).await?;
        Ok(data.get_decimals())
    }

    pub async fn get_asset_ticker(&self, asset: String) -> Result<String> {
        let asset_hash = Hash::from_hex(&asset).context("Invalid asset")?;
        let data = self.get_asset_data(&asset_hash).await?;
        Ok(data.get_ticker().to_string())
    }

    pub async fn get_asset_metadata(&self, asset: String) -> Result<String> {
        let asset_hash = Hash::from_hex(&asset).context("Invalid asset")?;
        let asset_data = self.get_asset_data(&asset_hash).await?;

        asset_metadata_json(&asset_data)
    }

    pub async fn get_contract_logs(&self, tx_hash: String) -> Result<String> {
        if !self.wallet.is_online().await {
            return Err(anyhow!("Wallet is offline"));
        }

        let hash = Hash::from_hex(&tx_hash).context("Invalid transaction hash")?;

        let network_handler = self.wallet.get_network_handler().lock().await;
        if let Some(handler) = network_handler.as_ref() {
            let api = handler.get_api();
            let result = api
                .get_contract_logs(&hash)
                .await
                .map_err(|e| anyhow!("Failed to fetch contract logs from daemon: {}", e))?;

            let json_str = serde_json::to_string(&result)?;
            Ok(json_str)
        } else {
            Err(anyhow!("Network handler not available"))
        }
    }

    pub async fn format_coin(
        &self,
        atomic_amount: u64,
        asset_hash: Option<String>,
    ) -> Result<String> {
        let asset = resolve_asset_hash(asset_hash.as_deref())?;

        let data = self.get_asset_data(&asset).await?;
        Ok(xelis_common::utils::format_coin(
            atomic_amount,
            data.get_decimals(),
        ))
    }

    async fn get_asset_data(&self, asset_hash: &Hash) -> Result<AssetData> {
        {
            let storage = self.wallet.get_storage().read().await;
            if storage.has_asset(asset_hash).await? {
                return storage.get_asset(asset_hash).await;
            }
        }

        // 3. offline guard
        if !self.wallet.is_online().await {
            return Err(anyhow!(
                "Asset {} not found in wallet storage/cache and wallet is offline",
                asset_hash
            ));
        }

        // 4. daemon
        let asset_data = {
            let network_handler = self.wallet.get_network_handler().lock().await;
            if let Some(handler) = network_handler.as_ref() {
                let api = handler.get_api();
                debug!("Fetching asset {} from daemon", asset_hash);
                let data = api
                    .get_asset(asset_hash)
                    .await
                    .map_err(|e| anyhow!("Failed to fetch asset from daemon: {}", e))?;

                data.inner
            } else {
                return Err(anyhow!("Network handler not available"));
            }
        };

        debug!(
            "Storing fetched asset {} from network, storing it in wallet storage",
            asset_hash
        );

        let mut storage = self.wallet.get_storage().write().await;
        storage
            .add_asset(asset_hash, asset_data.clone())
            .await
            .context("Error storing fetched asset in wallet storage")?;

        debug!("Asset {} stored in wallet storage", asset_hash);

        Ok(asset_data)
    }
}

#[cfg(test)]
mod tests;
