use std::collections::HashMap;

use anyhow::{Context, Result};
use flutter_rust_bridge::frb;
use xelis_common::{
    api::{DataElement, wallet::FeeBuilder},
    config::XELIS_ASSET,
    crypto::{
        address::{Address, AddressType},
        hash::Hash,
    },
    serializer::{Serializer, Writer},
    transaction::{EXTRA_DATA_LIMIT_SIZE, Transaction, TransactionType, Transfer},
    utils::get_network,
};
use xelis_common::crypto::key::{KeyPair, PublicKey};
use xelis_wallet::{mnemonics, transaction_builder::TransactionBuilder, wallet::WalletError};

#[frb(opaque)]
pub struct XelisKeyPair {
    pub key_pair: KeyPair,
}

impl XelisKeyPair {
    pub fn get_address(&self) -> Result<String> {
        Ok(self
            .key_pair
            .get_public_key()
            .to_address(get_network().is_mainnet())
            .as_string()?)
    }

    pub fn get_seed(&self, language_index: usize) -> Result<String> {
        let words = mnemonics::key_to_words(self.key_pair.get_private_key(), language_index)?;
        Ok(words.join(" "))
    }

    // pub fn sign(&self, data: String) -> RustOpaque<Signature> {
    //     RustOpaque::new(self.key_pair.sign(data.as_bytes()))
    // }
    //
    // pub fn verify_signature(&self, hash: String, signature: RustOpaque<Signature>) -> bool {
    //     self.key_pair
    //         .get_public_key()
    //         .verify_signature(&Hash::from_hex(hash).unwrap(), &signature)
    // }

    pub fn get_estimated_fees(
        &self,
        address: String,
        amount: u64,
        asset: String,
        nonce: u64,
    ) -> Result<u64> {
        let _address: Address = Address::from_string(&address).context("Invalid address")?;
        let _asset: Hash = Hash::from_hex(asset)?;

        let (key, address_type) = _address.split();

        let extra_data = match address_type {
            AddressType::Normal => None,
            AddressType::Data(data) => Some(data),
        };

        let fees = {
            let transfer = self.create_transfer(_asset, key, extra_data, amount)?;
            self.estimate_fees(nonce, TransactionType::Transfer(vec![transfer]))
        };
        Ok(fees)
    }

    pub fn create_tx(
        &self,
        address: String,
        amount: u64,
        asset: String,
        balance: u64,
        nonce: u64,
    ) -> Result<String> {
        let _address: Address = Address::from_string(&address).context("Invalid address")?;
        let _asset: Hash = Hash::from_hex(asset)?;

        let (key, address_type) = _address.split();
        let extra_data = match address_type {
            AddressType::Normal => None,
            AddressType::Data(data) => Some(data),
        };

        let tx = {
            let transfer = self.create_transfer(_asset, key, extra_data, amount)?;
            self.create_transaction(balance, nonce, TransactionType::Transfer(vec![transfer]))?
        };

        Ok(tx.to_hex())
    }

    fn create_transfer(
        &self,
        asset: Hash,
        key: PublicKey,
        extra_data: Option<DataElement>,
        amount: u64,
    ) -> Result<Transfer> {
        let extra_data = if let Some(data) = extra_data {
            let mut writer = Writer::new();
            data.write(&mut writer);

            if writer.total_write() > EXTRA_DATA_LIMIT_SIZE {
                return Err(WalletError::InvalidAddressParams.into());
            }
            Some(writer.bytes())
        } else {
            None
        };

        let transfer = Transfer {
            amount,
            asset: asset.clone(),
            to: key,
            extra_data,
        };

        Ok(transfer)
    }

    fn create_transaction(
        &self,
        balance: u64,
        nonce: u64,
        transaction_type: TransactionType,
    ) -> Result<Transaction> {
        let builder = TransactionBuilder::new(
            self.key_pair.get_public_key().clone(),
            transaction_type,
            nonce,
            FeeBuilder::Multiplier(1f64),
        );
        let assets_spent: HashMap<&Hash, u64> = builder.total_spent();

        let total_native_spent =
            assets_spent.get(&XELIS_ASSET).unwrap_or(&0) + builder.estimate_fees();
        if total_native_spent > balance {
            return Err(WalletError::NotEnoughFundsForFee(balance, total_native_spent).into());
        }

        Ok(builder.build(&self.key_pair)?)
    }

    fn estimate_fees(&self, nonce: u64, transaction_type: TransactionType) -> u64 {
        let builder = TransactionBuilder::new(
            self.key_pair.get_public_key().clone(),
            transaction_type,
            nonce,
            FeeBuilder::Multiplier(1f64),
        );
        builder.estimate_fees()
    }
}

pub fn create_key_pair(seed: Option<String>) -> Result<XelisKeyPair> {
    let keypair = if let Some(seed) = seed {
        let words: Vec<String> = seed.split_whitespace().map(str::to_string).collect();
        let key = mnemonics::words_to_key(words)?;
        KeyPair::from_private_key(key)
    } else {
        KeyPair::new()
    };
    Ok(XelisKeyPair {
        key_pair: keypair,
    })
}
