use anyhow::{Context, Result};
use flutter_rust_bridge::frb;
use serde_json::json;
use xelis_common::{crypto::Address, network::Network};

use super::models::wallet_dtos::IntegratedAddress;

// Check if the given address is valid
#[frb(sync)]
pub fn is_address_valid(str_address: String, network: Network) -> bool {
    match Address::from_string(&str_address) {
        Ok(address) => match network {
            Network::Mainnet => address.is_mainnet(),
            Network::Testnet => !address.is_mainnet(),
            Network::Dev => !address.is_mainnet(),
        },
        Err(_) => false,
    }
}

// Split integrated address (if any) into address and data
#[frb(sync)]
pub fn split_integrated_address(integrated_address: String) -> Result<String> {
    let address = Address::from_string(&integrated_address).context("Invalid address")?;
    let (data, address) = address.extract_data();
    Ok(json!(IntegratedAddress { address, data }).to_string())
}
