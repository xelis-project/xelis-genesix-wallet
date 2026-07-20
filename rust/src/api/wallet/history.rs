use std::io::Write;
use std::path::Path;

#[cfg(target_arch = "wasm32")]
use std::fs::File;
#[cfg(not(target_arch = "wasm32"))]
use tempfile::NamedTempFile;

use super::super::models::wallet_dtos::HistoryPageFilter;
use super::XelisWallet;
use crate::frb_generated::StreamSink;
use anyhow::{bail, Context, Result};
use log::{info, warn};
use serde::Serialize;
use xelis_common::api::wallet::NotifyEvent;
use xelis_common::tokio::sync::broadcast::{error::RecvError, Receiver};
use xelis_wallet::wallet::Event;

#[derive(Serialize)]
struct WalletEventEnvelope<'a> {
    event: NotifyEvent,
    data: &'a Event,
}

fn page_is_out_of_range(transaction_count: usize, page: usize, limit: usize) -> bool {
    let max_pages = transaction_count / limit + usize::from(transaction_count % limit != 0);
    page > max_pages
}

fn ensure_transactions_to_export(transaction_count: usize) -> Result<()> {
    if transaction_count == 0 {
        bail!("No transactions to export");
    }

    Ok(())
}

#[cfg(not(target_arch = "wasm32"))]
fn create_temporary_csv_file(destination: &Path) -> Result<NamedTempFile> {
    let directory = destination
        .parent()
        .filter(|parent| !parent.as_os_str().is_empty())
        .unwrap_or_else(|| Path::new("."));

    NamedTempFile::new_in(directory).context("Error while creating temporary CSV file")
}

#[cfg(not(target_arch = "wasm32"))]
fn persist_csv_file(mut temporary: NamedTempFile, destination: &Path) -> Result<()> {
    temporary
        .as_file_mut()
        .sync_all()
        .context("Error while syncing CSV file")?;
    temporary
        .persist(destination)
        .map_err(|error| error.error)
        .context("Error while replacing CSV file")?;
    Ok(())
}

fn serialize_wallet_event(event: &Event) -> Result<String> {
    serde_json::to_string(&WalletEventEnvelope {
        event: event.kind(),
        data: event,
    })
    .context("Error while serializing wallet event")
}

async fn forward_wallet_events<E>(
    mut receiver: Receiver<Event>,
    mut send: impl FnMut(String) -> std::result::Result<(), E>,
) {
    loop {
        match receiver.recv().await {
            Ok(event) => {
                let json_event = match serialize_wallet_event(&event) {
                    Ok(json_event) => json_event,
                    Err(error) => {
                        warn!("Unable to serialize wallet event: {error}");
                        continue;
                    }
                };

                if send(json_event).is_err() {
                    break;
                }
            }
            Err(RecvError::Lagged(skipped)) => {
                warn!("Events stream lagged; skipped {} messages", skipped);
            }
            Err(RecvError::Closed) => break,
        }
    }
}

impl XelisWallet {
    pub async fn get_history_count(&self) -> Result<usize> {
        let storage = self.wallet.get_storage().read().await;
        Ok(storage.get_transactions_count()?)
    }

    pub async fn history(&self, filter: HistoryPageFilter) -> Result<Vec<String>> {
        let mut txs: Vec<String> = Vec::new();
        let options = filter.options()?;

        let storage = self.wallet.get_storage().read().await;

        let txs_len = storage.get_transactions_count()?;
        info!("Transactions available: {}", txs_len);
        if txs_len == 0 {
            info!("No transactions available");
            return Ok(txs);
        }

        if let Some(limit) = filter.limit {
            if page_is_out_of_range(txs_len, filter.page, limit) {
                info!("Page out of range");

                return Ok(txs);
            }
        }

        let transactions = storage.get_filtered_transactions(options)?;

        for tx in transactions {
            let transaction_entry = tx.serializable(self.wallet.get_network().is_mainnet());
            let json_tx = serde_json::to_string(&transaction_entry)?;
            txs.push(json_tx);
        }

        Ok(txs)
    }

    pub async fn get_pending_transactions(&self) -> Result<Vec<String>> {
        let storage = self.wallet.get_storage().read().await;
        let mainnet = self.wallet.get_network().is_mainnet();

        storage
            .get_pending_txs()
            .iter()
            .cloned()
            .map(|tx| serde_json::to_string(&tx.serializable(mainnet)).map_err(Into::into))
            .collect()
    }

    pub async fn events_stream(&self, sink: StreamSink<String>) {
        let receiver = self.wallet.subscribe_events().await;
        forward_wallet_events(receiver, |event| sink.add(event)).await;
    }

    #[cfg(not(target_arch = "wasm32"))]
    pub async fn export_transactions_to_csv_file(
        &self,
        file_path: String,
        filter: HistoryPageFilter,
    ) -> Result<()> {
        let path = Path::new(&file_path);
        let mut temporary = create_temporary_csv_file(path)?;
        self.export_csv_transactions(filter, &mut temporary).await?;
        persist_csv_file(temporary, path)
    }

    #[cfg(target_arch = "wasm32")]
    pub async fn export_transactions_to_csv_file(
        &self,
        file_path: String,
        filter: HistoryPageFilter,
    ) -> Result<()> {
        let path = Path::new(&file_path);
        let mut file = File::create(path).context("Error while creating CSV file")?;
        self.export_csv_transactions(filter, &mut file).await
    }

    pub async fn convert_transactions_to_csv(&self, filter: HistoryPageFilter) -> Result<String> {
        let mut buffer = Vec::new();

        self.export_csv_transactions(filter, &mut buffer).await?;
        String::from_utf8(buffer).context("Error while converting CSV to string")
    }

    async fn export_csv_transactions(
        &self,
        filter: HistoryPageFilter,
        writer: &mut impl Write,
    ) -> Result<()> {
        let storage = self.wallet.get_storage().read().await;
        let transactions = storage.get_filtered_transactions(filter.options()?)?;

        ensure_transactions_to_export(transactions.len())?;

        self.wallet
            .export_transactions_in_csv(&storage, transactions, writer)
            .await
            .context("Error while exporting transactions to CSV")
    }
}

#[cfg(test)]
mod tests;
