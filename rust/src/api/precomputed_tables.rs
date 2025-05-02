use std::ops::ControlFlow;

use log::trace;
use xelis_common::crypto::ecdlp;
use xelis_wallet::precomputed_tables;

use crate::api::progress_report::{add_progress_report, ProgressReport};

// Precomputed tables for the wallet
// pub static CACHED_TABLES: Mutex<Option<precomputed_tables::PrecomputedTablesShared>> =
// Mutex::new(None);

pub enum PrecomputedTableType {
    L1Low,
    L1Medium,
    L1Full,
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
    let table_type = match precomputed_table_type {
        PrecomputedTableType::L1Low => precomputed_tables::L1_LOW,
        PrecomputedTableType::L1Medium => precomputed_tables::L1_MEDIUM,
        PrecomputedTableType::L1Full => precomputed_tables::L1_FULL,
    };
    precomputed_tables::has_precomputed_tables(Some(precomputed_tables_path.as_str()), table_type)
        .await
        .expect("Failed to check precomputed tables existence")
}
