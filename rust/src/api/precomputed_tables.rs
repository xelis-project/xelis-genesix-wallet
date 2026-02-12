use flutter_rust_bridge::frb;

use std::ops::ControlFlow;

use anyhow::{bail, Result};
use log::trace;
use serde::{Deserialize, Serialize};
use xelis_common::crypto::ecdlp;
use xelis_wallet::precomputed_tables;

use crate::api::progress_report::{add_progress_report, ProgressReport};

#[frb]
#[derive(Serialize, Deserialize, Debug, Clone)]
pub enum PrecomputedTableType {
    L1Low,
    L1Medium,
    L1Full,
    Custom(usize),
}

impl PrecomputedTableType {
    /// Convert to the actual L1 size used by the tables code.
    /// For Custom(n), this uses 1 << n and enforces 8 <= n <= 32.
    pub fn to_l1_size(&self) -> Result<usize> {
        match *self {
            PrecomputedTableType::L1Low => Ok(precomputed_tables::L1_LOW),
            PrecomputedTableType::L1Medium => Ok(precomputed_tables::L1_MEDIUM),
            PrecomputedTableType::L1Full => Ok(precomputed_tables::L1_FULL),
            PrecomputedTableType::Custom(size) => {
                if size < 16 || size >= 33 {
                    bail!("Invalid custom L1 size: {} (must be 16..33)", size);
                }
                Ok(size)
            }
        }
    }

    // Custom(_) variant forces a sealed class instead of a Dart enum, so adding generic helper maps
    pub fn name(&self) -> String {
        match self {
            PrecomputedTableType::L1Low => "l1Low".to_string(),
            PrecomputedTableType::L1Medium => "l1Medium".to_string(),
            PrecomputedTableType::L1Full => "l1Full".to_string(),
            PrecomputedTableType::Custom(n) => format!("custom({})", n),
        }
    }

    pub fn index(&self) -> u32 {
        match self {
            PrecomputedTableType::L1Low => 0,
            PrecomputedTableType::L1Medium => 1,
            PrecomputedTableType::L1Full => 2,
            PrecomputedTableType::Custom(_) => 3,
        }
    }
}

pub struct LogProgressTableGenerationReportFunction;

impl ecdlp::ProgressTableGenerationReportFunction for LogProgressTableGenerationReportFunction {
    fn report(&self, progress: f64, step: ecdlp::ReportStep) -> ControlFlow<()> {
        let step_str = format!("{:?}", step);
        add_progress_report(ProgressReport {
            progress,
            step: step_str,
            message: None,
        });
        trace!("Progress: {:.2}% on step {:?}", progress * 100.0, step);

        ControlFlow::Continue(())
    }
}

pub async fn are_precomputed_tables_available(
    precomputed_tables_path: String,
    precomputed_table_type: PrecomputedTableType,
) -> bool {
    precomputed_tables::has_precomputed_tables(
        Some(precomputed_tables_path.as_str()),
        precomputed_table_type
            .to_l1_size()
            .unwrap_or(precomputed_tables::L1_LOW),
    )
    .await
    .expect("Failed to check precomputed tables existence")
}
