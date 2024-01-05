use std::sync::Arc;

use flutter_rust_bridge::frb;
use xelis_common::utils::get_network;
use xelis_wallet::wallet::Wallet;

use crate::api::api::TOKIO_RUNTIME;

#[frb(opaque)]
pub struct XelisWallet {
    wallet: Arc<Wallet>,
}

impl XelisWallet {
    pub fn get_address_str(&self) -> anyhow::Result<String> {
        let address = self.wallet.get_address().to_string();
        Ok(address)
    }

    pub fn get_seed(&self, language_index: usize) -> anyhow::Result<String> {
        self.wallet.get_seed(language_index)
    }

    pub fn get_nonce(&self) -> u64 {
        let mut rt_guard = TOKIO_RUNTIME.lock().expect("Get tokio runtime");
        let rt = rt_guard.as_mut().expect("Tokio runtime present");
        let _guard = rt.enter();

        rt.block_on(self.wallet.get_nonce())
    }

    pub fn set_online_mode(&self, daemon_address: String) -> anyhow::Result<()> {
        let mut rt_guard = TOKIO_RUNTIME.lock().expect("Get tokio runtime");
        let rt = rt_guard.as_mut().expect("Tokio runtime present");
        let _guard = rt.enter();

        Ok(rt.block_on(self.wallet.set_online_mode(&daemon_address))?)
    }

    pub fn set_offline_mode(&self) -> anyhow::Result<()> {
        let mut rt_guard = TOKIO_RUNTIME.lock().expect("Get tokio runtime");
        let rt = rt_guard.as_mut().expect("Tokio runtime present");
        let _guard = rt.enter();

        Ok(rt.block_on(self.wallet.set_offline_mode())?)
    }

    pub fn is_online(&self) -> bool {
        let mut rt_guard = TOKIO_RUNTIME.lock().expect("Get tokio runtime");
        let rt = rt_guard.as_mut().expect("Tokio runtime present");
        let _guard = rt.enter();

        rt.block_on(self.wallet.is_online())
    }
}

pub fn create_xelis_wallet(
    name: String,
    password: String,
    seed: Option<String>,
) -> anyhow::Result<XelisWallet> {
    let network = get_network();
    let xelis_wallet = Wallet::create(name, password, seed, network)?;
    Ok(XelisWallet {
        wallet: xelis_wallet,
    })
}

pub fn open_xelis_wallet(name: String, password: String) -> anyhow::Result<XelisWallet> {
    let network = get_network();
    let xelis_wallet = Wallet::open(name, password, network)?;
    Ok(XelisWallet {
        wallet: xelis_wallet,
    })
}
