use anyhow::Error;
use flutter_rust_bridge::RustOpaque;
use std::sync::Arc;
pub use xelis_wallet::wallet::Wallet;
// pub use xelis_common::crypto::key::{KeyPair, PrivateKey, PublicKey};

pub fn new_wallet(
    name: String,
    password: String,
    seed: Option<String>,
) -> Result<Arc<Wallet>, Error> {
    let wallet = Wallet::create(name, password, seed)?;
    let opaque_wallet = RustOpaque::new(wallet);
    Ok(wallet)
}

/*pub fn create_key_pair() -> RustOpaque<KeyPair> {
    RustOpaque::new(KeyPair::new())
}

pub fn get_address(key_pair: RustOpaque<KeyPair>) -> Result<String, anyhow::Error> {
    Ok(key_pair.get_public_key().to_address().as_string()?)
}
*/

/*pub enum Platform {
    Unknown,
    Android,
    Ios,
    Windows,
    Unix,
    MacIntel,
    MacApple,
    Wasm,
}

pub fn platform() -> Platform {
    if cfg!(windows) {
        Platform::Windows
    } else if cfg!(target_os = "android") {
        Platform::Android
    } else if cfg!(target_os = "ios") {
        Platform::Ios
    } else if cfg!(all(target_os = "macos", target_arch = "aarch64")) {
        Platform::MacApple
    } else if cfg!(target_os = "macos") {
        Platform::MacIntel
    } else if cfg!(target_family = "wasm") {
        Platform::Wasm
    } else if cfg!(unix) {
        Platform::Unix
    } else {
        Platform::Unknown
    }
}*/

pub fn rust_release_mode() -> bool {
    cfg!(not(debug_assertions))
}
