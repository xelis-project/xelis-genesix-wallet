use anyhow::{Context, Result};
use flutter_rust_bridge::frb;
use serde::{Deserialize, Serialize};
use serde_json::json;
use xelis_common::{api::DataElement, crypto::Address};

// Check if the given address is valid
#[frb(sync)]
pub fn is_address_valid(str_address: String) -> bool {
    match Address::from_string(&str_address) {
        Ok(_) => true,
        Err(_) => false,
    }
}

#[derive(Serialize, Deserialize, Clone, Debug)]
pub struct IntegratedAddress {
    address: Address,
    data: Option<DataElement>,
}

// Split integrated address (if any) into address and data
#[frb(sync)]
pub fn split_integrated_address_json(integrated_address: String) -> Result<String> {
    let address = Address::from_string(&integrated_address).context("Invalid address")?;
    let (data, address) = address.extract_data();
    Ok(json!(IntegratedAddress { address, data }).to_string())
}
