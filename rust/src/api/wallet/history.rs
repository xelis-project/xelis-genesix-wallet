use std::fs::File;
use std::io::Write;
use std::path::Path;

use super::super::models::wallet_dtos::HistoryPageFilter;
use super::XelisWallet;
use crate::frb_generated::StreamSink;
use anyhow::{bail, Context, Result};
use log::{info, warn};
use serde_json::json;
use xelis_common::tokio::sync::broadcast::error::RecvError;

fn page_is_out_of_range(transaction_count: usize, page: usize, limit: usize) -> bool {
    let max_pages = transaction_count / limit + usize::from(transaction_count % limit != 0);
    page > max_pages
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
        let mut rx = self.wallet.subscribe_events().await;

        loop {
            let result = rx.recv().await;
            match result {
                Ok(event) => {
                    let json_event = json!({"event": event.kind(), "data": event}).to_string();
                    if sink.add(json_event).is_err() {
                        break;
                    }
                }
                Err(RecvError::Lagged(skipped)) => {
                    warn!("Events stream lagged; skipped {} messages", skipped);
                    continue;
                }
                Err(RecvError::Closed) => {
                    break;
                }
            }
        }
    }

    pub async fn export_transactions_to_csv_file(
        &self,
        file_path: String,
        filter: HistoryPageFilter,
    ) -> Result<()> {
        let path = Path::new(&file_path);
        let mut file = File::create(&path).context("Error while creating CSV file")?;

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

        if transactions.is_empty() {
            bail!("No transactions to export");
        }

        self.wallet
            .export_transactions_in_csv(&storage, transactions, writer)
            .await
            .context("Error while exporting transactions to CSV")
    }
}

#[cfg(test)]
mod tests;
