use anyhow::{Error, Result};
use flutter_rust_bridge::*;
pub use xelis_common::crypto::key::{KeyPair, PrivateKey, PublicKey};

pub fn create_key_pair() -> RustOpaque<KeyPair> {
    RustOpaque::new(KeyPair::new())
}

pub fn get_address(key_pair: RustOpaque<KeyPair>) -> Result<String, Error> {
    Ok(key_pair.get_public_key().to_address().as_string()?)
}
