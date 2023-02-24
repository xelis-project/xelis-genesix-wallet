use anyhow::Error;
use flutter_rust_bridge::*;
use std::fmt::Debug;
pub use std::panic::{RefUnwindSafe, UnwindSafe};
use std::sync::{Arc, Mutex, RwLock};
use xelis_common::crypto::key::KeyPair;
use xelis_wallet::network_handler::SharedNetworkHandler;
use xelis_wallet::storage::EncryptedStorage;
pub use xelis_wallet::wallet::Wallet;
// pub use xelis_common::crypto::key::{KeyPair, PrivateKey, PublicKey};

/*#[frb(mirror(Wallet))]
pub struct _Wallet {
    // Encrypted Wallet Storage
    storage: RwLock<EncryptedStorage>,
    // Private & Public key linked for this wallet
    keypair: KeyPair,
    // network handler for online mode to keep wallet synced
    network_handler: Mutex<Option<SharedNetworkHandler>>,
    // network: Network
}*/
/*
pub struct XelisWallet {
    pub wallet: Arc<Wallet>,
}

impl XelisWallet {
    pub fn create(name: String,
                  password: String,
                  seed: Option<String>, ) -> Self {
        Self {
            wallet: Wallet::create(name, password, seed).unwrap()
        }
    }
}*/

pub fn new_wallet(name: String, password: String, seed: Option<String>) -> RustOpaque<Arc<Wallet>> {
    let wallet = Wallet::create(name, password, seed).unwrap();
    RustOpaque::new(wallet)
}

// pub fn get_address(wallet: RustOpaque<Arc<Wallet>>) -> Result<String, Error> {
//     Ok(wallet.lock().unwrap().get_address().as_string()?)
// }

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
