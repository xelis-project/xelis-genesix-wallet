use std::future::Future;

use anyhow::{Context, Result};
use serde_json::json;
use xelis_common::api::{DataElement, DataValue};
use xelis_common::config::XELIS_ASSET;
use xelis_common::crypto::{Address, Hash};
use xelis_common::serializer::Serializer;
use xelis_common::transaction::builder::{TransactionTypeBuilder, TransferBuilder};
use xelis_common::transaction::BurnPayload;

use crate::api::models::wallet_dtos::{SummaryTransaction, Transfer};

use super::super::{amounts, XelisWallet};

pub(super) fn encrypt_extra_data_or_default(value: Option<bool>) -> bool {
    value.unwrap_or(true)
}

pub(in crate::api::wallet) fn amount_after_fee(
    amount: u64,
    fee: u64,
    asset: &Hash,
    insufficient_funds_context: &'static str,
) -> Result<u64> {
    let amount = if asset == &XELIS_ASSET {
        amount
            .checked_sub(fee)
            .context(insufficient_funds_context)?
    } else {
        amount
    };

    (amount > 0)
        .then_some(amount)
        .context(insufficient_funds_context)
}

pub(in crate::api::wallet) fn build_transfer(
    destination: Address,
    amount: u64,
    asset: Hash,
    extra_data: Option<String>,
    encrypt_extra_data: Option<bool>,
) -> TransferBuilder {
    TransferBuilder {
        destination,
        amount,
        asset,
        extra_data: extra_data.map(|value| DataElement::Value(DataValue::String(value))),
        encrypt_extra_data: encrypt_extra_data_or_default(encrypt_extra_data),
    }
}

pub(super) fn build_transfer_from_input(
    transfer: Transfer,
    asset: Hash,
    decimals: u8,
) -> Result<TransferBuilder> {
    let amount = amounts::checked_atomic_amount(transfer.float_amount, decimals)
        .context("Error while converting amount to atomic format")?;
    let destination = Address::from_string(&transfer.str_address).context("Invalid address")?;

    Ok(build_transfer(
        destination,
        amount,
        asset,
        transfer.extra_data,
        transfer.encrypt_extra_data,
    ))
}

pub(super) fn build_transfer_all_type(
    destination: Address,
    balance: u64,
    fee: u64,
    asset: Hash,
    extra_data: Option<String>,
    encrypt_extra_data: Option<bool>,
) -> Result<TransactionTypeBuilder> {
    let amount = amount_after_fee(balance, fee, &asset, "Insufficient balance for fees")?;
    let transfer = build_transfer(destination, amount, asset, extra_data, encrypt_extra_data);

    Ok(TransactionTypeBuilder::Transfers(vec![transfer]))
}

pub(super) fn build_burn_type(asset: Hash, amount: u64) -> TransactionTypeBuilder {
    TransactionTypeBuilder::Burn(BurnPayload { amount, asset })
}

pub(super) fn build_burn_all_type(
    asset: Hash,
    balance: u64,
    fee: u64,
) -> Result<TransactionTypeBuilder> {
    let amount = amount_after_fee(
        balance,
        fee,
        &asset,
        "Insufficient balance to pay burn transaction fees",
    )?;

    Ok(build_burn_type(asset, amount))
}

pub(super) fn transaction_summary_json(
    hash: &Hash,
    fee: u64,
    transaction_type: TransactionTypeBuilder,
) -> String {
    json!(SummaryTransaction {
        hash: hash.to_hex(),
        fee,
        transaction_type,
    })
    .to_string()
}

pub(in crate::api::wallet) async fn create_transfers(
    wallet: &XelisWallet,
    transfers: Vec<Transfer>,
) -> Result<TransactionTypeBuilder> {
    create_transfers_with_decimals(transfers, |asset| async move {
        let storage = wallet.wallet.get_storage().read().await;
        Ok(storage.get_asset(&asset).await?.get_decimals())
    })
    .await
}

pub(super) async fn create_transfers_with_decimals<LoadDecimals, LoadDecimalsFuture>(
    transfers: Vec<Transfer>,
    mut load_decimals: LoadDecimals,
) -> Result<TransactionTypeBuilder>
where
    LoadDecimals: FnMut(Hash) -> LoadDecimalsFuture,
    LoadDecimalsFuture: Future<Output = Result<u8>>,
{
    let mut builders = Vec::new();

    for transfer in transfers {
        let asset = Hash::from_hex(&transfer.asset_hash).context("Invalid asset")?;
        let decimals = load_decimals(asset.clone())
            .await
            .context("Error while converting amount to atomic format")?;
        let transfer_builder = build_transfer_from_input(transfer, asset, decimals)?;

        builders.push(transfer_builder);
    }

    Ok(TransactionTypeBuilder::Transfers(builders))
}

#[cfg(test)]
mod tests;
